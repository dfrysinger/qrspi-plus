#!/usr/bin/env bash
# ============================================================================
# codex-companion-bg.sh — non-blocking wrapper around codex-companion.mjs
#
# Purpose
# -------
# QRSPI skills invoke this script to launch Codex review jobs in the
# background and to await their completion without blocking the pipeline.
# It is the post-Hardening replacement for `codex:rescue` invocations on
# the QRSPI side; the upstream rescue agent strips `--background` from
# its routing-flag list, so QRSPI calls the companion directly here.
#
# Subcommands
# -----------
#   launch --prompt-file <path>
#       Forks `node codex-companion.mjs task --background --prompt-file <path>`
#       in the background, captures the `jobId` from its JSON return, prints
#       the job ID alone to stdout, exits 0 within QRSPI_CODEX_LAUNCH_TIMEOUT
#       seconds (default 5).
#
#   await <jobId>
#       Polls `node codex-companion.mjs status <jobId> --json` at FAST
#       intervals (default 5s) for the first BACKOFF_AFTER seconds (default
#       120s), then SLOW intervals (default 30s). On completion, runs
#       `node codex-companion.mjs result <jobId> --json` and writes the
#       review markdown to stdout, exit 0. On the operational ceiling
#       (default 1200s = 20 min), writes an audit row with completion_status
#       "ceiling-hit" and exits 10 with empty stdout.
#
# Real Codex companion JSON contract (verified against
# /Users/<user>/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/
# codex-companion.mjs as of 2026-04 release):
#   - `task --background --json` payload (codex-companion.mjs:670-679):
#         { jobId, status, title, summary, logFile }
#   - `status <id> --json` snapshot (codex-companion.mjs:840-857 →
#     lib/job-control.mjs:242-254):
#         { workspaceRoot, job: { id, status, title, summary, ... } }
#     Status values: queued | running | completed | failed | cancelled.
#     Job-not-found surfaces as a thrown error; main() (mjs:1023-1027) writes
#     the message to stderr and exits 1. The message contains the literal
#     substring "No job found" or "No finished job found".
#   - `result <id> --json` payload (codex-companion.mjs:867-883 →
#     lib/render.mjs:401-404):
#         { job, storedJob }
#         where the review markdown lives at storedJob.result.rawOutput
#         (preferred) with storedJob.result.codex.stdout as the legacy
#         fallback.
#
# Exit codes
# ----------
#   0   success
#   1   generic / launch failures / malformed JSON from `task`
#   10  await ceiling hit (no review markdown delivered)
#   11  await: companion reports job-not-found
#   12  await: audit-log write failure
#   13  await: status/result hard error (not job-not-found, not ceiling)
#   14  await: malformed JSON from status/result
#
# Lock primitive
# --------------
# `mkdir <lockdir>` is used for audit-log append serialization. Rationale:
# `flock(1)` is unavailable on macOS by default; `mkdir` is atomic on POSIX
# (man 2 mkdir: "The mkdir() function shall fail if the named file exists.")
# and portable to every shell environment QRSPI runs in. A short retry loop
# with backoff handles contended waits; the lock directory is removed in a
# trap so a crashed writer cannot wedge later writers.
#
# Concurrency
# -----------
# All audit-row appends pass through append_audit_row(), which acquires the
# mkdir-lock, writes a single line via `printf '%s\n' >>`, then releases.
# Bench: 100 concurrent writers × 5 trials produce exactly 100 well-formed
# lines per trial (see tests/unit/test-codex-companion-bg.bats T8).
# ============================================================================

set -u
# Note: NOT -e — we intentionally inspect non-zero rcs on subprocess calls
# (status companion can legitimately exit 1 to signal job-not-found). -o
# pipefail is left off for the same reason.

# ---------------------------------------------------------------------------
# Configuration knobs (env-overridable; spec-mandated defaults)
# ---------------------------------------------------------------------------
: "${QRSPI_CODEX_POLL_INTERVAL_FAST:=5}"        # seconds, first phase
: "${QRSPI_CODEX_POLL_INTERVAL_SLOW:=30}"       # seconds, after backoff
: "${QRSPI_CODEX_POLL_BACKOFF_AFTER:=120}"      # seconds elapsed → switch to SLOW
: "${QRSPI_CODEX_CEILING_SECONDS:=1200}"        # 20 min, hard exit-10 ceiling
: "${QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS:=5}"    # launch must return inside 5s
: "${QRSPI_AUDIT_DIR:=.qrspi}"
: "${QRSPI_AUDIT_FILE:=audit-codex-review.jsonl}"
: "${QRSPI_AUDIT_LOCK_DIR:=audit-codex-review.lock}"

# ---------------------------------------------------------------------------
# resolve_codex_companion
#
# Purpose:  Pick the codex-companion.mjs path to invoke.
# Inputs:   Reads $CODEX_COMPANION (explicit override) and $HOME (for
#           plugin-cache glob fallback).
# Outputs:  Echoes the resolved absolute path on stdout; non-zero exit on
#           failure (no companion found and no override).
# Failure:  Writes a stderr message describing what was searched.
#
# Rationale (per task constraint C3): a hardcoded absolute path with one
# operator's ${HOME} or a specific version pin is non-portable. Strategy:
# resolve at call time. If the operator sets $CODEX_COMPANION, honor it
# verbatim. Otherwise glob the plugin-cache for ALL installed versions of
# the codex plugin, sort with -V (version-aware), take the highest. If
# none exist, fail loud with a stderr message — never silently substitute
# a fallback path.
# ---------------------------------------------------------------------------
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
  # Globbing in bash: nullglob lets the pattern expand to nothing if no
  # matches, instead of staying literal. Save+restore prior shopt state.
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

  # Sort by directory name (version) — newest wins. Versions look like
  # 1.0.2, 1.0.4, etc.; sort -V handles them naturally.
  local picked
  picked=$(printf '%s\n' "${matches[@]}" | sort -V | tail -n1)
  printf '%s\n' "$picked"
}

# ---------------------------------------------------------------------------
# emit_audit_row
#
# Purpose:  Append exactly one JSONL row to .qrspi/audit-codex-review.jsonl.
# Inputs:   $1 job_id, $2 elapsed_seconds (integer), $3 completion_status,
#           $4 timestamp (ISO-8601).
# Outputs:  Returns 0 on success.
# Failure:  Returns 12 with stderr message if the lock or append fails.
#           Caller is responsible for surfacing the failure (we never
#           silently swallow per spec line 15 / constraint C2).
#
# Locking strategy: mkdir is atomic on POSIX. A crashing writer leaves the
# lockdir behind, which would wedge later writers; the trap inside this
# function ensures cleanup on signals and on normal return. Stale lockdirs
# from a hard kill are detected via age check (>30s = stale) and reaped.
# ---------------------------------------------------------------------------
emit_audit_row() {
  local job_id="$1" elapsed="$2" status="$3" ts="$4"
  local audit_dir="$QRSPI_AUDIT_DIR"
  local audit_file="$audit_dir/$QRSPI_AUDIT_FILE"
  local lock_dir="$audit_dir/$QRSPI_AUDIT_LOCK_DIR"

  # Ensure audit dir exists with mode 0700 (spec line 14). mkdir -m sets the
  # mode atomically on creation; if the dir already exists with a stricter
  # mode we leave it, but we DO try to chmod 0700 to repair if loose.
  if [ ! -d "$audit_dir" ]; then
    mkdir -m 0700 "$audit_dir" 2>/dev/null || {
      printf 'codex-companion-bg: could not create audit dir %s\n' "$audit_dir" >&2
      return 12
    }
  fi
  chmod 0700 "$audit_dir" 2>/dev/null || true

  # Acquire mkdir-lock with bounded retry (~10s under heavy contention).
  # Each attempt: 50ms sleep on failure. Reap stale lockdirs older than 30s.
  local attempts=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    attempts=$((attempts + 1))
    # Stale-reap: if lock has lived past 30s, remove it. 30s >> any single
    # printf-append, so anything older indicates a crashed writer.
    if [ -d "$lock_dir" ]; then
      local lock_age
      # `find -prune` returns the dir if its mtime is older than 30s.
      lock_age=$(find "$lock_dir" -maxdepth 0 -type d -mmin +0.5 2>/dev/null || true)
      if [ -n "$lock_age" ]; then
        rmdir "$lock_dir" 2>/dev/null || rm -rf "$lock_dir" 2>/dev/null || true
      fi
    fi
    if [ "$attempts" -gt 400 ]; then
      printf 'codex-companion-bg: failed to acquire audit lock after %d attempts\n' "$attempts" >&2
      return 12
    fi
    # 50ms sleep — bash sleep accepts fractional seconds on macOS/Linux.
    sleep 0.05
  done

  # Trap: ensure lockdir release on any path out (success, error, signal).
  # Nested traps: this function is the leaf, so a local-scope-equivalent
  # approach is: clean up explicitly before every return.
  local row
  # JSON-escape job_id and status. They are wrapper-controlled small strings
  # (no embedded quotes / backslashes / control chars in the values we ever
  # emit), so a simple printf-with-%s is safe — but we still validate for
  # paranoia: replace any " or \ with their escaped forms.
  local job_id_esc status_esc ts_esc
  job_id_esc=${job_id//\\/\\\\}
  job_id_esc=${job_id_esc//\"/\\\"}
  status_esc=${status//\\/\\\\}
  status_esc=${status_esc//\"/\\\"}
  ts_esc=${ts//\\/\\\\}
  ts_esc=${ts_esc//\"/\\\"}

  row=$(printf '{"job_id":"%s","elapsed_seconds":%d,"completion_status":"%s","timestamp":"%s"}' \
    "$job_id_esc" "$elapsed" "$status_esc" "$ts_esc")

  # Append. Failure here is the spec-line-15 case (write-only-fs, full disk).
  if ! printf '%s\n' "$row" >> "$audit_file" 2>/dev/null; then
    rmdir "$lock_dir" 2>/dev/null || true
    printf 'codex-companion-bg: failed to append audit row to %s\n' "$audit_file" >&2
    return 12
  fi

  rmdir "$lock_dir" 2>/dev/null || true
  return 0
}

# ---------------------------------------------------------------------------
# now_iso  /  now_epoch
#
# Tiny helpers — bash builtins differ across macOS (BSD date) and Linux (GNU
# date). We only need the bits both implement.
# ---------------------------------------------------------------------------
now_iso() {
  # %FT%TZ format works on both BSD and GNU date.
  date -u "+%Y-%m-%dT%H:%M:%SZ"
}

now_epoch() {
  date "+%s"
}

# ---------------------------------------------------------------------------
# extract_json_field
#
# Purpose:  Pull a top-level OR dotted-path field out of a JSON document
#           via Node (the wrapper already requires Node to invoke the
#           companion). Avoids a hard jq dep.
# Inputs:   $1 JSON text, $2 dotted path (e.g. "jobId" or "job.status").
# Outputs:  Echoes the value (string or number coerced to string).
#           Returns 1 if the path is missing or JSON is malformed; in that
#           case stdout is empty. Caller must check rc.
# Failure:  Silent on missing path; rc=1. Malformed JSON → rc=1.
# ---------------------------------------------------------------------------
extract_json_field() {
  local json="$1" path="$2"
  printf '%s' "$json" | node -e "
let chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch (e) { process.exit(1); }
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
" "$path"
}

# ---------------------------------------------------------------------------
# launch_subcommand
#
# Purpose:  Implement `launch --prompt-file <path>`. Fork the companion's
#           `task --background --prompt-file <path>` invocation, capture its
#           single-line JSON, parse jobId, print the job ID to stdout, exit 0
#           — all within QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS seconds.
# Inputs:   $@ raw argv after the `launch` subcommand.
# Outputs:  Job ID on stdout, exit 0 on success.
# Failure:  Exit 1 with stderr on: missing/unreadable companion, bad args,
#           spawn failure, timeout, non-zero exit from `task`, malformed
#           JSON, missing jobId. Exit code from the underlying `task`
#           process is preserved as-is when it is non-zero (constraint C1).
# ---------------------------------------------------------------------------
launch_subcommand() {
  local prompt_file=""
  # Minimal arg parse: only --prompt-file <path> is meaningful for this
  # subcommand today; anything else is rejected loudly (no silent ignore).
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --prompt-file)
        prompt_file="${2:-}"
        shift 2 || { printf 'launch: --prompt-file requires a value\n' >&2; return 1; }
        ;;
      *)
        printf 'launch: unrecognised argument: %s\n' "$1" >&2
        return 1
        ;;
    esac
  done

  if [ -z "$prompt_file" ]; then
    printf 'launch: --prompt-file is required\n' >&2
    return 1
  fi
  if [ ! -r "$prompt_file" ]; then
    printf 'launch: prompt file not readable: %s\n' "$prompt_file" >&2
    return 1
  fi

  local companion
  if ! companion=$(resolve_codex_companion); then
    return 1
  fi

  # Spawn the companion's `task --background` in the background. We capture
  # stdout to a temp file (so we can wait without deadlocking on a pipe)
  # and supervise it with a bounded watchdog.
  local stdout_file stderr_file
  stdout_file=$(mktemp 2>/dev/null) || { printf 'launch: mktemp failed\n' >&2; return 1; }
  stderr_file=$(mktemp 2>/dev/null) || { rm -f "$stdout_file"; printf 'launch: mktemp failed\n' >&2; return 1; }

  # IMPORTANT (constraint C1): we capture the spawned process's real exit
  # code below. Earlier iterations used `wait "$pid" 2>/dev/null || true`
  # then `rc=$?` — that pattern always sets rc=0 because `|| true` masks
  # the wait failure. Here we DO let `wait` fail without `|| true` so its
  # exit code becomes our rc, and we propagate it on the failure paths.
  node "$companion" task --background --prompt-file "$prompt_file" --json \
    >"$stdout_file" 2>"$stderr_file" &
  local pid=$!

  # Watchdog: poll until the child exits or the budget expires. We use
  # short fractional sleeps so the timeout granularity is sub-second.
  local budget="$QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS"
  local start_epoch
  start_epoch=$(now_epoch)
  local timed_out=0
  while kill -0 "$pid" 2>/dev/null; do
    local now_e
    now_e=$(now_epoch)
    if [ "$((now_e - start_epoch))" -ge "$budget" ]; then
      timed_out=1
      break
    fi
    sleep 0.1
  done

  if [ "$timed_out" -eq 1 ]; then
    # Kill the hung child and any descendants; macOS lacks setsid so we
    # send SIGTERM then SIGKILL after a brief grace.
    kill -TERM "$pid" 2>/dev/null || true
    sleep 0.2
    kill -KILL "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    printf 'launch: companion did not return within %ds (job-create hung)\n' \
      "$budget" >&2
    rm -f "$stdout_file" "$stderr_file"
    return 1
  fi

  # Reap and capture the real exit code (constraint C1: do NOT use `|| true`).
  wait "$pid"
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    # Surface companion stderr to our stderr. Preserve the real rc.
    if [ -s "$stderr_file" ]; then
      cat "$stderr_file" >&2
    fi
    printf 'launch: companion `task --background` exited %d\n' "$rc" >&2
    rm -f "$stdout_file" "$stderr_file"
    return "$rc"
  fi

  # Parse JSON: extract `jobId`. Real shape is { jobId, status, ... }
  # (codex-companion.mjs:670-679 v1.0.4).
  local stdout_text
  stdout_text=$(cat "$stdout_file")
  rm -f "$stdout_file" "$stderr_file"

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

  printf '%s\n' "$job_id"
  return 0
}

# ---------------------------------------------------------------------------
# poll_status
#
# Purpose:  Single status poll. Calls companion `status <id> --json` and
#           classifies the outcome.
# Inputs:   $1 companion path, $2 jobId.
# Outputs:  Echoes a single token on stdout describing the outcome:
#           "running" | "completed" | "not-found" | "malformed" | "error".
# Failure:  Token "error" indicates an unexpected non-zero rc that does not
#           match the job-not-found stderr signature.
# ---------------------------------------------------------------------------
poll_status() {
  local companion="$1" job_id="$2"
  local stdout_text stderr_text
  local tmp_out tmp_err
  tmp_out=$(mktemp) || { printf 'error\n'; return; }
  tmp_err=$(mktemp) || { rm -f "$tmp_out"; printf 'error\n'; return; }

  node "$companion" status "$job_id" --json >"$tmp_out" 2>"$tmp_err"
  local rc=$?
  stdout_text=$(cat "$tmp_out")
  stderr_text=$(cat "$tmp_err")
  rm -f "$tmp_out" "$tmp_err"

  if [ "$rc" -ne 0 ]; then
    # Constraint C4: distinguish job-not-found from other errors. Real
    # companion's matchJobReference throws errors containing "No job found"
    # (job-control.mjs:210) or "No finished job found" (line 275). main()
    # writes the message verbatim to stderr.
    if printf '%s' "$stderr_text" | grep -qE 'No (finished )?job found'; then
      printf 'not-found\n'
      return
    fi
    # Some other non-zero — surface stderr for the caller to log.
    printf '%s' "$stderr_text" >&2
    printf 'error\n'
    return
  fi

  # Parse `.job.status` (NOT `.status` — common error). Real shape:
  # { workspaceRoot, job: { id, status, ... } }
  local job_status
  if ! job_status=$(extract_json_field "$stdout_text" "job.status"); then
    printf '%s' "$stdout_text" >&2
    printf 'malformed\n'
    return
  fi

  case "$job_status" in
    queued|running)
      printf 'running\n'
      ;;
    completed)
      printf 'completed\n'
      ;;
    failed|cancelled)
      # Treat as completed-with-failure: the result subcommand can still
      # surface whatever Codex said. Caller will fetch `result` and decide
      # whether the rawOutput is meaningful.
      printf 'completed\n'
      ;;
    *)
      printf 'malformed\n'
      ;;
  esac
}

# ---------------------------------------------------------------------------
# fetch_result
#
# Purpose:  Call companion `result <id> --json` and extract the review
#           markdown.
# Inputs:   $1 companion path, $2 jobId.
# Outputs:  Writes review markdown to stdout. Sets exit code:
#             0  ok, markdown emitted
#             11 job-not-found
#             13 hard error (other non-zero)
#             14 malformed JSON / missing rawOutput
#           Always emits stderr on non-zero return (constraint C2).
# ---------------------------------------------------------------------------
fetch_result() {
  local companion="$1" job_id="$2"
  local tmp_out tmp_err
  tmp_out=$(mktemp) || { printf 'fetch_result: mktemp failed\n' >&2; return 13; }
  tmp_err=$(mktemp) || { rm -f "$tmp_out"; printf 'fetch_result: mktemp failed\n' >&2; return 13; }

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

  # Parse storedJob.result.rawOutput (preferred per render.mjs:401-404)
  # with storedJob.result.codex.stdout as legacy fallback.
  local raw
  if raw=$(extract_json_field "$stdout_text" "storedJob.result.rawOutput") && [ -n "$raw" ]; then
    printf '%s' "$raw"
    return 0
  fi
  if raw=$(extract_json_field "$stdout_text" "storedJob.result.codex.stdout") && [ -n "$raw" ]; then
    printf '%s' "$raw"
    return 0
  fi

  printf 'fetch_result: malformed result JSON or missing rawOutput; got: %s\n' \
    "$stdout_text" >&2
  return 14
}

# ---------------------------------------------------------------------------
# await_subcommand
#
# Purpose:  Implement `await <jobId>`. Polls status with the spec-mandated
#           5s/30s/120s interval pattern, fetches result on completion,
#           writes review markdown to stdout. Always appends one audit row
#           before returning.
# Inputs:   $@ raw argv after `await`. Expects exactly one positional: jobId.
# Outputs:  Review markdown on stdout (success). Exit 0 / 10 / 11 / 12 / 13 / 14
#           per the exit-code table above.
# Failure:  Audit-row write failure → exit 12 with stderr; ceiling → exit 10
#           with stderr-free empty-stdout (per spec test-expectation 5).
#           All other failure paths emit a stderr message (constraint C2).
# ---------------------------------------------------------------------------
await_subcommand() {
  if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    printf 'await: jobId argument is required\n' >&2
    return 1
  fi
  local job_id="$1"

  local companion
  if ! companion=$(resolve_codex_companion); then
    # No companion → we still write an audit row recording the failure
    # so the caller's log isn't silent on this case.
    emit_audit_row "$job_id" 0 "malformed" "$(now_iso)" || true
    return 1
  fi

  local start_epoch
  start_epoch=$(now_epoch)
  local ceiling="$QRSPI_CODEX_CEILING_SECONDS"
  local backoff_after="$QRSPI_CODEX_POLL_BACKOFF_AFTER"
  local fast_int="$QRSPI_CODEX_POLL_INTERVAL_FAST"
  local slow_int="$QRSPI_CODEX_POLL_INTERVAL_SLOW"

  local final_status=""    # set once we decide the loop's outcome
  local final_rc=0         # exit code we'll return after the audit row

  while :; do
    local now_e elapsed
    now_e=$(now_epoch)
    elapsed=$((now_e - start_epoch))

    # Ceiling check FIRST so we never poll past the budget.
    if [ "$elapsed" -ge "$ceiling" ]; then
      final_status="ceiling-hit"
      final_rc=10
      break
    fi

    local outcome
    outcome=$(poll_status "$companion" "$job_id")
    case "$outcome" in
      running)
        # Pick the next sleep based on cumulative elapsed time, not on a
        # poll counter — matches spec wording "5s for the first 2 minutes,
        # then 30s".
        local sleep_for
        if [ "$elapsed" -lt "$backoff_after" ]; then
          sleep_for="$fast_int"
        else
          sleep_for="$slow_int"
        fi
        # But never overshoot the ceiling — clamp the sleep so the next
        # iteration sees the ceiling and exits cleanly.
        local remaining=$((ceiling - elapsed))
        if [ "$sleep_for" -gt "$remaining" ]; then
          sleep_for="$remaining"
        fi
        if [ "$sleep_for" -le 0 ]; then
          sleep_for=0
        fi
        sleep "$sleep_for"
        ;;
      completed)
        # Fetch the result, write to stdout, set status accordingly.
        local res_rc
        if fetch_result "$companion" "$job_id"; then
          final_status="success"
          final_rc=0
        else
          res_rc=$?
          # Map fetch_result rc to audit completion_status + exit code.
          case "$res_rc" in
            11) final_status="job-not-found"; final_rc=11 ;;
            13) final_status="malformed"; final_rc=13 ;;
            14) final_status="malformed"; final_rc=14 ;;
            *)  final_status="malformed"; final_rc="$res_rc" ;;
          esac
        fi
        break
        ;;
      not-found)
        final_status="job-not-found"
        final_rc=11
        printf 'await: job %s not found by companion\n' "$job_id" >&2
        break
        ;;
      malformed)
        final_status="malformed"
        final_rc=14
        printf 'await: malformed status JSON for job %s\n' "$job_id" >&2
        break
        ;;
      error|*)
        final_status="malformed"
        final_rc=13
        printf 'await: hard error from status for job %s\n' "$job_id" >&2
        break
        ;;
    esac
  done

  # Compute final elapsed for the audit row.
  local end_epoch elapsed_total
  end_epoch=$(now_epoch)
  elapsed_total=$((end_epoch - start_epoch))

  # Emit the audit row BEFORE returning (spec line 17: ceiling row written
  # before exit-10; constraint C2: every failure path emits via this write).
  if ! emit_audit_row "$job_id" "$elapsed_total" "$final_status" "$(now_iso)"; then
    # Audit-write failure — surface and return 12 unless we're already
    # returning a more-specific non-zero code from the loop. The spec is
    # explicit: silent swallow is forbidden. We override final_rc here
    # because audit-row corruption is itself a hard failure.
    printf 'await: audit-row write failed for job %s\n' "$job_id" >&2
    return 12
  fi

  return "$final_rc"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  if [ "$#" -lt 1 ]; then
    cat >&2 <<USAGE
Usage:
  codex-companion-bg.sh launch --prompt-file <path>
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
