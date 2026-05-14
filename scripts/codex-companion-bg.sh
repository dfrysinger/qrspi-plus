#!/usr/bin/env bash
# codex-companion-bg.sh — non-blocking wrapper around codex-companion.mjs.
#
# Subcommands:
#   launch                        Fork companion `task --background` and print
#                                 the captured jobId; exit 0 within ~5s.
#                                 The prompt is read from stdin (stdin must
#                                 not be a TTY). The legacy --prompt-file
#                                 path-arg form was retired in commit 21/22
#                                 of the #110 migration sequence.
#   await <jobId>                 Poll status (5s/30s with backoff at 120s),
#                                 fetch result on completion, write review
#                                 markdown to stdout; ceiling at 1200s.
#
# Exit codes:
#   0   success
#   1   generic / launch failures
#   10  await ceiling hit
#   11  await: job-not-found
#   13  await: status/result hard error or launch bad JSON
#   14  await: malformed JSON from status/result

set -u
# NOT -e: we inspect non-zero rcs from subprocesses (status legitimately exits
# 1 to signal job-not-found). pipefail is similarly off.

# Global guard for the phase-fallback audit line.  Set to 0 at script init so
# that the first poll_status invocation that triggers the job.phase fallback
# emits the stderr note exactly once per wrapper process; subsequent
# invocations within the same process suppress the line to avoid log-spam.
_CODEX_PHASE_FALLBACK_LOGGED=0

: "${QRSPI_CODEX_POLL_INTERVAL_FAST:=5}"
: "${QRSPI_CODEX_POLL_INTERVAL_SLOW:=30}"
: "${QRSPI_CODEX_POLL_BACKOFF_AFTER:=120}"
: "${QRSPI_CODEX_CEILING_SECONDS:=1200}"
: "${QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS:=5}"

# ---------------------------------------------------------------------------
# Companion path resolution: explicit $CODEX_COMPANION wins; else glob the
# plugin cache for installed versions (sort -V, newest wins). Never silent
# fallback to a hardcoded path.
resolve_codex_companion() {
  if [ -n "${CODEX_COMPANION:-}" ]; then
    if [ -x "$CODEX_COMPANION" ] || [ -r "$CODEX_COMPANION" ]; then
      printf '%s\n' "$CODEX_COMPANION"
      return 0
    fi
    printf 'codex-companion-bg: CODEX_COMPANION="%s" is not readable\n' \
      "$CODEX_COMPANION" >&2
    return 1
  fi

  local pattern="${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs"
  local prev_nullglob
  prev_nullglob=$(shopt -p nullglob)
  shopt -s nullglob
  local matches=( $pattern )
  eval "$prev_nullglob"

  if [ "${#matches[@]}" -eq 0 ]; then
    printf 'codex-companion-bg: no codex-companion.mjs found under %s and CODEX_COMPANION is unset\n' \
      "$pattern" >&2
    return 1
  fi

  local picked
  picked=$(printf '%s\n' "${matches[@]}" | sort -V | tail -n1)
  printf '%s\n' "$picked"
}

now_iso() {
  local v
  if ! v=$(date -u "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null) || [ -z "$v" ]; then
    printf 'codex-companion-bg: date -u failed\n' >&2
    return 1
  fi
  printf '%s' "$v"
}

now_epoch() {
  local v
  if ! v=$(date "+%s" 2>/dev/null) || [ -z "$v" ]; then
    printf 'codex-companion-bg: date +%%s failed\n' >&2
    return 1
  fi
  printf '%s' "$v"
}

# ---------------------------------------------------------------------------
# extract_json_field <json> <dotted-path>
#
# Pull a string/number/boolean field from a JSON document. Returns 0 with the
# value on stdout; rc=1 (empty stdout) on missing path or malformed JSON.
#
# IMPLEMENTATION NOTE: With `node -e SCRIPT ...args`, node does NOT add a
# script-path entry to process.argv (no script file exists). The first user
# arg therefore lands at process.argv[1], not [2]. We pass `--` before the
# path so any future readers see an explicit option terminator; node consumes
# the `--` token, so it does not appear in argv. Verified via:
#   node -e 'console.log(process.argv)' -- foo
#   → [<binary>, "foo"]
extract_json_field() {
  local json="$1" path="$2"
  printf '%s' "$json" | node -e "
let chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch (e) { process.exit(1); }
  // argv[1] is the path arg under node -e (no script-path entry exists).
  const segs = process.argv[1].split('.');
  let cur = data;
  for (const s of segs) {
    if (cur == null || typeof cur !== 'object') { process.exit(1); }
    cur = cur[s];
  }
  if (cur === undefined || cur === null) { process.exit(1); }
  if (typeof cur === 'string' || typeof cur === 'number' || typeof cur === 'boolean') {
    process.stdout.write(String(cur));
  } else {
    process.stdout.write(JSON.stringify(cur));
  }
});
" -- "$path"
}

# ---------------------------------------------------------------------------
# spawn_with_timeout <budget_secs> <stdout_file> <stderr_file> <cmd...>
#
# Run cmd with stdout/stderr redirected; kill if it exceeds budget. Sets two
# globals: SPAWN_RC (real wait rc, or unset on timeout) and SPAWN_TIMED_OUT.
spawn_with_timeout() {
  local budget="$1" stdout_file="$2" stderr_file="$3"; shift 3

  "$@" >"$stdout_file" 2>"$stderr_file" &
  local pid=$!

  local start_epoch
  start_epoch=$(now_epoch) || { kill -KILL "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; SPAWN_RC=1; SPAWN_TIMED_OUT=0; return; }
  SPAWN_TIMED_OUT=0
  while kill -0 "$pid" 2>/dev/null; do
    local now_e
    now_e=$(now_epoch) || break
    if [ "$((now_e - start_epoch))" -ge "$budget" ]; then
      SPAWN_TIMED_OUT=1
      break
    fi
    sleep 0.1
  done

  if [ "$SPAWN_TIMED_OUT" -eq 1 ]; then
    kill -TERM "$pid" 2>/dev/null
    sleep 0.2
    kill -KILL "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    SPAWN_RC=124
    return
  fi

  # Reap and capture the real exit code (no `|| true` mask).
  wait "$pid"
  SPAWN_RC=$?
}

# ---------------------------------------------------------------------------
# parse_launch_output <stdout_text>
#
# Extract jobId from companion `task --background --json` payload. Echoes the
# job ID on success; rc=1 with stderr message on malformed/missing.
parse_launch_output() {
  local stdout_text="$1"
  local job_id
  if ! job_id=$(extract_json_field "$stdout_text" "jobId"); then
    printf 'launch: malformed JSON or missing jobId in companion output: %s\n' \
      "$stdout_text" >&2
    return 1
  fi
  if [ -z "$job_id" ]; then
    printf 'launch: empty jobId from companion\n' >&2
    return 1
  fi
  printf '%s' "$job_id"
}

# ---------------------------------------------------------------------------
# launch_subcommand
#
# The launch subcommand reads the prompt from stdin (path-arg form retired in
# commit 21/22 of the #110 migration sequence). Any positional/flag argument
# is rejected — including the legacy --prompt-file form — to keep the
# trust boundary tight and prevent silent fallback to a stale path-arg caller.
launch_subcommand() {
  if [ "$#" -gt 0 ]; then
    printf 'launch: unrecognised argument: %s (path-arg form retired; pipe prompt on stdin)\n' "$1" >&2
    return 1
  fi

  if [ -t 0 ]; then
    printf 'launch: stdin must not be a TTY (pipe a non-empty prompt on stdin)\n' >&2
    return 1
  fi

  local stdin_temp
  stdin_temp=$(mktemp -t codex-companion-bg-stdin.XXXXXX) || {
    printf 'launch: mktemp failed for stdin capture\n' >&2
    return 1
  }
  cat > "$stdin_temp"
  if [ ! -s "$stdin_temp" ]; then
    rm -f "$stdin_temp"
    printf 'launch: stdin was empty\n' >&2
    return 1
  fi
  local prompt_file="$stdin_temp"

  local companion
  if ! companion=$(resolve_codex_companion); then
    rm -f "$stdin_temp"
    return 1
  fi

  local stdout_file stderr_file
  stdout_file=$(mktemp -t codex-companion-bg.XXXXXX) || { rm -f "$stdin_temp"; printf 'launch: mktemp failed\n' >&2; return 1; }
  stderr_file=$(mktemp -t codex-companion-bg.XXXXXX) || { rm -f "$stdin_temp" "$stdout_file"; printf 'launch: mktemp failed\n' >&2; return 1; }

  local SPAWN_RC=0 SPAWN_TIMED_OUT=0
  # The companion reads --prompt-file synchronously inside spawn_with_timeout;
  # stdin_temp (if set) remains on disk until after spawn_with_timeout returns.
  spawn_with_timeout "$QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS" "$stdout_file" "$stderr_file" \
    node "$companion" task --background --prompt-file "$prompt_file" --json

  # stdin_temp no longer needed: companion has read the file (or timed out).
  rm -f "$stdin_temp"

  if [ "$SPAWN_TIMED_OUT" -eq 1 ]; then
    printf 'launch: companion did not return within %ds (job-create hung)\n' \
      "$QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS" >&2
    rm -f "$stdout_file" "$stderr_file"
    return 1
  fi

  if [ "$SPAWN_RC" -ne 0 ]; then
    if [ -s "$stderr_file" ]; then
      cat "$stderr_file" >&2
    fi
    printf 'launch: companion `task --background` exited %d\n' "$SPAWN_RC" >&2
    rm -f "$stdout_file" "$stderr_file"
    return "$SPAWN_RC"
  fi

  local stdout_text
  stdout_text=$(cat "$stdout_file")
  rm -f "$stdout_file" "$stderr_file"

  local job_id
  if ! job_id=$(parse_launch_output "$stdout_text"); then
    return 1
  fi
  printf '%s\n' "$job_id"
  return 0
}

# ---------------------------------------------------------------------------
# poll_status <companion> <jobId>
#
# Single status poll. Echoes one of:
#   running
#   completed:<terminal-status>     (terminal-status ∈ completed|failed|cancelled)
#   not-found
#   malformed
#   error
#
# The `completed:<terminal>` form lets the caller distinguish the real terminal
# status (completed vs failed vs cancelled) without re-invoking `node ... status`
# a second time (one fewer subprocess per terminal job).
poll_status() {
  local companion="$1" job_id="$2"
  local tmp_out tmp_err
  tmp_out=$(mktemp -t codex-companion-bg.XXXXXX) || { printf 'error\n'; return; }
  tmp_err=$(mktemp -t codex-companion-bg.XXXXXX) || { rm -f "$tmp_out"; printf 'error\n'; return; }

  node "$companion" status "$job_id" --json >"$tmp_out" 2>"$tmp_err"
  local rc=$?
  local stdout_text stderr_text
  stdout_text=$(cat "$tmp_out")
  stderr_text=$(cat "$tmp_err")
  rm -f "$tmp_out" "$tmp_err"

  # Verified against codex-companion.mjs v1.0.4: matchJobReference (job-control.mjs:210, 275)
  # throws errors with "No job found" / "No finished job found"; main() (mjs:1023-1027)
  # writes the message verbatim to stderr and exits 1.
  if [ "$rc" -ne 0 ]; then
    if printf '%s' "$stderr_text" | grep -qE 'No (finished )?job found'; then
      printf 'not-found\n'
      return
    fi
    printf '%s' "$stderr_text" >&2
    printf 'error\n'
    return
  fi

  # Parse `.job.status` (mjs:840-857; job-control.mjs:242-254 v1.0.4).
  local job_status
  if ! job_status=$(extract_json_field "$stdout_text" "job.status"); then
    # job.status is absent from the payload.  Attempt the job.phase fallback
    # before falling through to the malformed terminal case.
    #
    # Phase → lifecycle mapping (design.md § G7, single source of truth):
    #   finalizing | done | reviewing                          → completed:completed
    #   starting | running | investigating | editing | verifying → running
    #   anything else (incl. absent or empty)                  → malformed (exit 14)
    local job_phase
    if job_phase=$(extract_json_field "$stdout_text" "job.phase") && [ -n "$job_phase" ]; then
      case "$job_phase" in
        finalizing|done|reviewing)
          # Emit the audit line once per wrapper process to stderr so monitoring
          # harnesses can detect broker-omitting-job.status patterns over time.
          # Subsequent invocations within the same process suppress the line.
          # The stderr surface is NOT part of the caller contract; callers MUST
          # parse only stdout and exit code.
          if [ "${_CODEX_PHASE_FALLBACK_LOGGED:-0}" -eq 0 ]; then
            printf '[codex-companion-bg] phase fallback active: %s → completed\n' \
              "$job_phase" >&2
            _CODEX_PHASE_FALLBACK_LOGGED=1
          fi
          printf 'completed:completed\n'
          return
          ;;
        starting|running|investigating|editing|verifying)
          if [ "${_CODEX_PHASE_FALLBACK_LOGGED:-0}" -eq 0 ]; then
            printf '[codex-companion-bg] phase fallback active: %s → running\n' \
              "$job_phase" >&2
            _CODEX_PHASE_FALLBACK_LOGGED=1
          fi
          printf 'running\n'
          return
          ;;
      esac
    fi
    # Both job.status and job.phase are absent, or job.phase carries a value
    # outside the mapping table.  Fall through to the existing malformed terminal
    # case — this is a genuine protocol violation, not a recoverable phase.
    printf '%s' "$stdout_text" >&2
    printf 'malformed\n'
    return
  fi

  case "$job_status" in
    queued|running)   printf 'running\n' ;;
    completed)        printf 'completed:completed\n' ;;
    failed)           printf 'completed:failed\n' ;;
    cancelled)        printf 'completed:cancelled\n' ;;
    *)                printf 'malformed\n' ;;
  esac
}

# ---------------------------------------------------------------------------
# fetch_result <companion> <jobId>
#
# Call companion `result <id> --json` and extract the review markdown.
# Verified against codex-companion.mjs v1.0.4 + lib/render.mjs:401-445:
# the renderer falls back through five sources in order. We mirror that chain
# so failed/cancelled jobs (which carry errorMessage but no rawOutput) still
# surface meaningful text rather than being mislabeled "malformed".
#
# Fallback chain:
#   (a) storedJob.result.rawOutput          (preferred, render.mjs:401-402)
#   (b) storedJob.result.codex.stdout       (legacy, render.mjs:403)
#   (c) storedJob.rendered                  (render.mjs:413, failed/cancelled)
#   (d) job.errorMessage                    (render.mjs:437, "Cancelled by user.")
#   (e) storedJob.errorMessage              (render.mjs:439)
#
# Exit codes:
#   0   ok, markdown emitted
#   11  job-not-found
#   13  hard error (other non-zero)
#   14  malformed JSON / no extractable text from any fallback
fetch_result() {
  local companion="$1" job_id="$2"
  local tmp_out tmp_err
  tmp_out=$(mktemp -t codex-companion-bg.XXXXXX) || { printf 'fetch_result: mktemp failed\n' >&2; return 13; }
  tmp_err=$(mktemp -t codex-companion-bg.XXXXXX) || { rm -f "$tmp_out"; printf 'fetch_result: mktemp failed\n' >&2; return 13; }

  node "$companion" result "$job_id" --json >"$tmp_out" 2>"$tmp_err"
  local rc=$?
  local stdout_text stderr_text
  stdout_text=$(cat "$tmp_out")
  stderr_text=$(cat "$tmp_err")
  rm -f "$tmp_out" "$tmp_err"

  if [ "$rc" -ne 0 ]; then
    if printf '%s' "$stderr_text" | grep -qE 'No (finished )?job found'; then
      printf '%s' "$stderr_text" >&2
      return 11
    fi
    printf '%s' "$stderr_text" >&2
    printf 'fetch_result: companion `result` exited %d\n' "$rc" >&2
    return 13
  fi

  # Walk the fallback chain. Each extract_json_field returns rc=1 with empty
  # stdout when the path is absent — that's our signal to try the next.
  local raw
  if raw=$(extract_json_field "$stdout_text" "storedJob.result.rawOutput") && [ -n "$raw" ]; then
    printf '%s' "$raw"; return 0
  fi
  if raw=$(extract_json_field "$stdout_text" "storedJob.result.codex.stdout") && [ -n "$raw" ]; then
    printf '%s' "$raw"; return 0
  fi
  if raw=$(extract_json_field "$stdout_text" "storedJob.rendered") && [ -n "$raw" ]; then
    printf '%s' "$raw"; return 0
  fi
  # [CodexF1-resolved-by-comment]
  # Links (d) and (e) below intentionally diverge from render.mjs:421-445.
  # The real renderer's else-branch builds a structured header block
  # (`# <title>`, `Job: <id>`, `Status: <status>`, optional Codex session ID
  # / Resume hint, optional Summary) and then appends `job.errorMessage`
  # (link d) or `storedJob.errorMessage` (link e) as a body line — emitting
  # `"No captured result payload was stored for this job."` if both are
  # absent. The QRSPI wrapper deliberately bypasses that header formatting
  # and surfaces the bare errorMessage string, because the QRSPI caller's
  # contract is "give me the markdown the codex review produced." For
  # failed/cancelled jobs the errorMessage IS the substantive content; the
  # title/status/job-id metadata is already known to the caller (it just
  # invoked `await <jobId>`). Re-rendering the header block here would only
  # add noise to the captured-text output. This is acceptable per codex's
  # own resolution suggestion: not a defect for the wrapper's purpose.
  if raw=$(extract_json_field "$stdout_text" "job.errorMessage") && [ -n "$raw" ]; then
    printf '%s' "$raw"; return 0
  fi
  if raw=$(extract_json_field "$stdout_text" "storedJob.errorMessage") && [ -n "$raw" ]; then
    printf '%s' "$raw"; return 0
  fi

  printf 'fetch_result: malformed result JSON or no extractable review text; got: %s\n' \
    "$stdout_text" >&2
  return 14
}

# ---------------------------------------------------------------------------
# await_subcommand
#
# Parse the positional jobId, then poll/await and stream the result markdown
# to stdout.
await_subcommand() {
  local job_id=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --)
        shift
        if [ "$#" -ge 1 ] && [ -z "$job_id" ]; then
          job_id="$1"
          shift
        fi
        ;;
      -*)
        printf 'await: unrecognised flag: %s\n' "$1" >&2
        return 1
        ;;
      *)
        if [ -z "$job_id" ]; then
          job_id="$1"
          shift
        else
          printf 'await: unexpected extra positional argument: %s\n' "$1" >&2
          return 1
        fi
        ;;
    esac
  done

  if [ -z "$job_id" ]; then
    printf 'await: jobId argument is required\n' >&2
    return 1
  fi

  local companion
  if ! companion=$(resolve_codex_companion); then
    return 1
  fi

  local start_epoch
  start_epoch=$(now_epoch) || return 1
  local ceiling="$QRSPI_CODEX_CEILING_SECONDS"
  local backoff_after="$QRSPI_CODEX_POLL_BACKOFF_AFTER"
  local fast_int="$QRSPI_CODEX_POLL_INTERVAL_FAST"
  local slow_int="$QRSPI_CODEX_POLL_INTERVAL_SLOW"

  local final_rc=0

  while :; do
    local now_e elapsed
    now_e=$(now_epoch) || return 1
    elapsed=$((now_e - start_epoch))

    if [ "$elapsed" -ge "$ceiling" ]; then
      final_rc=10
      break
    fi

    local outcome
    outcome=$(poll_status "$companion" "$job_id")
    case "$outcome" in
      running)
        local sleep_for
        if [ "$elapsed" -lt "$backoff_after" ]; then
          sleep_for="$fast_int"
        else
          sleep_for="$slow_int"
        fi
        local remaining=$((ceiling - elapsed))
        if [ "$sleep_for" -gt "$remaining" ]; then
          sleep_for="$remaining"
        fi
        if [ "$sleep_for" -le 0 ]; then
          sleep_for=0
        fi
        sleep "$sleep_for"
        ;;
      completed:*)
        # Terminal status arrives encoded by poll_status as
        # "completed:<terminal>"; we don't currently need to differentiate
        # the terminal status here — fetch_result handles all three.
        local res_rc=0
        if fetch_result "$companion" "$job_id"; then
          final_rc=0
        else
          res_rc=$?
          case "$res_rc" in
            11) final_rc=11 ;;
            14) final_rc=14 ;;
            *)  final_rc=13 ;;
          esac
        fi
        break
        ;;
      not-found)
        final_rc=11
        printf 'await: job %s not found by companion\n' "$job_id" >&2
        break
        ;;
      malformed)
        final_rc=14
        printf 'await: malformed status JSON for job %s\n' "$job_id" >&2
        break
        ;;
      error|*)
        final_rc=13
        printf 'await: hard error from status for job %s\n' "$job_id" >&2
        break
        ;;
    esac
  done

  return "$final_rc"
}

# ---------------------------------------------------------------------------
main() {
  if [ "$#" -lt 1 ]; then
    cat >&2 <<'USAGE'
Usage:
  codex-companion-bg.sh launch          (pipe prompt on stdin)
  codex-companion-bg.sh await <jobId>
USAGE
    return 1
  fi
  local sub="$1"; shift
  case "$sub" in
    launch) launch_subcommand "$@" ;;
    await)  await_subcommand "$@" ;;
    *)
      printf 'codex-companion-bg: unknown subcommand: %s\n' "$sub" >&2
      return 1
      ;;
  esac
}

main "$@"
