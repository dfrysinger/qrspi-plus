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
#                                 Post-launch verification: the jobId is
#                                 verified via an internal status call before
#                                 being emitted; on phantom (not-found or
#                                 malformed), the task subcommand is retried
#                                 exactly once. Exit 15 (LAUNCH_PHANTOM) on
#                                 double-phantom.
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
#   15  launch: LAUNCH_PHANTOM — both jobId attempts failed verification

set -u
# NOT -e: we inspect non-zero rcs from subprocesses (status legitimately exits
# 1 to signal job-not-found). pipefail is similarly off.

# Named exit constants — all values must be distinct and must not collide with
# any POSIX-reserved or existing wrapper exit codes (0/1/10/11/13/14).
#   LAUNCH_PHANTOM (15): both post-launch verification attempts returned
#   not-found or malformed.  Exit 15 is reserved exclusively for this case.
#   Callers MUST NOT emit any jobId on stdout when exiting 15.
readonly LAUNCH_PHANTOM=15

# Global guard for the phase-fallback audit line.  Set to 0 at script init so
# that the first poll_status invocation that triggers the job.phase fallback
# emits the stderr note exactly once per wrapper process; subsequent
# invocations within the same process suppress the line to avoid log-spam.
CODEX_PHASE_FALLBACK_LOGGED=0

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
# run_task_once <companion> <prompt_file>
#
# Execute one `companion task --background --prompt-file <prompt_file> --json`
# call within the launch timeout.  Echoes the extracted jobId on stdout (rc=0)
# or returns non-zero on any failure (timeout, non-zero companion exit, bad JSON,
# missing jobId).  The caller is responsible for removing prompt_file.
run_task_once() {
  local companion="$1" prompt_file="$2"

  local stdout_file stderr_file
  stdout_file=$(mktemp -t codex-companion-bg.XXXXXX) || { printf 'launch: mktemp failed\n' >&2; return 1; }
  stderr_file=$(mktemp -t codex-companion-bg.XXXXXX) || { rm -f "$stdout_file"; printf 'launch: mktemp failed\n' >&2; return 1; }

  local SPAWN_RC=0 SPAWN_TIMED_OUT=0
  spawn_with_timeout "$QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS" "$stdout_file" "$stderr_file" \
    node "$companion" task --background --prompt-file "$prompt_file" --json

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
  printf '%s' "$job_id"
}

# ---------------------------------------------------------------------------
# verify_job_id <companion> <job_id>
#
# Issue a single poll_status call to verify the jobId is known to the broker.
# Returns 0 (verified) when the lifecycle is a positive broker acknowledgement
# (running or completed:*); returns 1 (unverified) on not-found, malformed,
# or error.  An 'error' lifecycle means the status call itself crashed /
# timed out / hit a permissions failure — that does NOT prove the broker
# knows the jobId, so it must fall through to the retry branch rather than
# be silently emitted as a successful verification.
#
# Design note: malformed falls through to the retry branch (does not exit 14)
# because exit 14 is reserved for the public `status` subcommand's external
# contract; the internal verification step is not a caller-visible path.
verify_job_id() {
  local companion="$1" job_id="$2"
  local lifecycle
  lifecycle=$(poll_status "$companion" "$job_id")
  case "$lifecycle" in
    not-found|malformed|error)
      # not-found: broker explicitly does not know this jobId.
      # malformed: response unparseable; cannot conclude either way.
      # error:     status call crashed before it could check.
      # All three force a retry.
      return 1
      ;;
    *)
      # running, completed:*, or any phase-fallback-recovered value —
      # the broker positively acknowledged the jobId.
      return 0
      ;;
  esac
}

# ---------------------------------------------------------------------------
# launch_subcommand
#
# The launch subcommand reads the prompt from stdin (path-arg form retired in
# commit 21/22 of the #110 migration sequence). Any positional/flag argument
# is rejected — including the legacy --prompt-file form — to keep the
# trust boundary tight and prevent silent fallback to a stale path-arg caller.
#
# Post-launch verification: after capturing the candidate jobId from the broker
# response, one internal status call verifies the job is known.  On phantom
# (not-found or malformed), the entire task subcommand is retried exactly once.
# Retry cap: 1 (maximum 2 total launches per invocation).
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

  # stdin_temp is cleaned up at every exit point in this function rather than
  # via a trap. This script deliberately runs without `set -e` / `set -o
  # pipefail` (callers depend on numeric return codes propagating from
  # internal helpers), and a cleanup trap would need careful scope to avoid
  # firing in subshells spawned by command substitution. Repeating `rm -f` in
  # each branch is intentional — do NOT replace with a trap without auditing
  # the subshell-spawning helpers (run_task_once, verify_job_id, poll_status).

  # --- Attempt 1 ---
  local job_id_1
  if ! job_id_1=$(run_task_once "$companion" "$prompt_file"); then
    rm -f "$stdin_temp"
    return 1
  fi

  if verify_job_id "$companion" "$job_id_1"; then
    # Happy path: first attempt verified.  Emit jobId, no additional stderr.
    rm -f "$stdin_temp"
    printf '%s\n' "$job_id_1"
    return 0
  fi

  # --- Retry (attempt 2) ---
  # First attempt unverified (not-found, malformed, or error).  Retry once.
  local job_id_2
  if ! job_id_2=$(run_task_once "$companion" "$prompt_file"); then
    # Broker-layer error on the retry launch: surface the existing launch-failure
    # exit unchanged.  This is not the double-phantom case (exit 15); the task
    # subcommand itself failed, which is a different failure mode.
    rm -f "$stdin_temp"
    return 1
  fi

  rm -f "$stdin_temp"

  if verify_job_id "$companion" "$job_id_2"; then
    # Retry-success path: emit the second jobId and write the distinguishing
    # stderr note.  This note is written only on the retry-success path.
    printf 'launch: first jobId failed verification, retried\n' >&2
    printf '%s\n' "$job_id_2"
    return 0
  fi

  # Double-phantom: both attempts unverifiable.  Exit LAUNCH_PHANTOM (15).
  # No jobId is emitted on stdout.
  printf 'launch: both jobId attempts failed verification (LAUNCH_PHANTOM)\n' >&2
  return "$LAUNCH_PHANTOM"
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
      local lifecycle
      case "$job_phase" in
        finalizing|done|reviewing)
          lifecycle=completed
          ;;
        starting|running|investigating|editing|verifying)
          lifecycle=running
          ;;
        *)
          lifecycle=
          ;;
      esac
      if [ -n "$lifecycle" ]; then
        # Emit the audit line once per wrapper process to stderr so monitoring
        # harnesses can detect broker-omitting-job.status patterns over time.
        # Subsequent invocations within the same process suppress the line.
        # The stderr surface is NOT part of the caller contract; callers MUST
        # parse only stdout and exit code.
        if [ "$CODEX_PHASE_FALLBACK_LOGGED" -eq 0 ]; then
          printf '[codex-companion-bg] phase fallback active: %s → %s\n' \
            "$job_phase" "$lifecycle" >&2
          CODEX_PHASE_FALLBACK_LOGGED=1
        fi
        if [ "$lifecycle" = completed ]; then
          printf 'completed:completed\n'
        else
          printf 'running\n'
        fi
        return
      fi
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
# _status_to_exit_code <status>
#
# Single source of truth for the status-to-exit-code mapping used by
# disk_state_fallback and await_subcommand's broker-served terminal branch.
# Maps a job lifecycle status string to the wrapper's public exit code for
# that terminal state when no output payload is extractable from the record.
#
# Mirrors the exit-code semantics of the broker-served happy path:
#   completed  → 14  (terminal but no extractable output → malformed)
#   failed     → 13  (hard error)
#   cancelled  → 13  (hard error, same bucket as failed)
#   *          → 1   (unknown status → caller treats as miss)
#
# Usage: _status_to_exit_code "$status_string"; local ec=$?
_status_to_exit_code() {
  case "$1" in
    completed)  return 14 ;;
    failed)     return 13 ;;
    cancelled)  return 13 ;;
    *)          return 1  ;;
  esac
}

# ---------------------------------------------------------------------------
# _emit_recovery_note <job_id>
#
# Single source of truth for the disk-recovery stderr note.  Called from each
# successful source branch in disk_state_fallback so the wording is defined
# in exactly one place.
#
# Single-emission discipline: each call site MUST be immediately followed by
# `return 0` (or a terminal-exit path).  Do not invoke this helper from a
# fall-through code path.
_emit_recovery_note() {
  printf 'await: recovered %s from disk (broker reported not-found)\n' "$1" >&2
}

# ---------------------------------------------------------------------------
# disk_state_fallback <job_id>
#
# Consult the broker's on-disk state when poll_status returns not-found.
# Invoked exclusively from await_subcommand's not-found branch.
#
# Path layout mirrors lib/state.mjs:29-43:
#   $CLAUDE_PLUGIN_DATA/state/<slug>-<sha256(realpath)[:16]>/state.json
#   $CLAUDE_PLUGIN_DATA/state/<slug>-<sha256(realpath)[:16]>/jobs/<jobId>.json
#
# Read budget: at most 2 file reads per call (state.json + jobs/<id>.json on hit).
# No directory scan, glob, or re-read within the same call.
#
# TOCTOU: state.json and jobs/<jobId>.json reads are non-atomic. An attacker with
# write access to the state directory could swap the per-job file between reads.
# Mitigated by the broker's exclusive ownership of the state directory at the
# OS-permission level; not enforced in-wrapper.
#
# Trust boundary: rawOutput and errorMessage are read from a broker-controlled
# state directory and emitted verbatim. Caller is responsible for terminal-escape
# handling. We do not strip ANSI sequences because the broker-served happy-path
# is also verbatim.
#
# Return codes (internal only — not part of the await public contract):
#   0   Successful recovery: output written to stdout, recovery note on stderr.
#   13  Job record found but status indicates failure (errorMessage on stderr,
#       nothing on stdout).  Exit 13 mirrors the hard-error exit used by
#       await_subcommand for broker-served non-recoverable errors (see fetch_result
#       and await_subcommand's error-case mappings in this file).
#   1   Miss: state.json absent/unreadable/invalid/jobId-absent, or per-job
#       record absent/unreadable/invalid.  Caller falls through to existing
#       terminal not-found exit (11).
disk_state_fallback() {
  local job_id="$1"

  # Path-resolution hard-stop: $CLAUDE_PLUGIN_DATA must be set and non-empty.
  # If absent, take the existing terminal not-found exit without any read.
  if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
    return 1
  fi

  # jobId format guard — belt-and-suspenders, independent of upstream verify_job_id.
  # job_id must be a safe filename component: no slashes, no '..' sequences,
  # no empty string, no leading-dot names (dotfiles are not valid broker jobIds).
  case "$job_id" in
    '' | */* | *..* | .*)
      printf 'await: malformed jobId rejected at disk-state fallback\n' >&2
      return 1
      ;;
  esac

  # Compute the broker-canonical state-directory path (mirrors lib/state.mjs:29-43).
  # Uses node to replicate the slug/hash construction exactly.
  # Both slugSource and the hash input are derived from canonicalRoot (realpathSync
  # output) so the computed path matches what the broker wrote regardless of symlinks.
  local state_dir
  state_dir=$(node -e "
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');
const pluginData = process.argv[1];
// Resolve workspace root the same way the broker does: git rev-parse --show-toplevel
// from the current working directory, falling back to cwd when not in a git repo.
let workspaceRoot;
try {
  workspaceRoot = execSync('git rev-parse --show-toplevel', {
    encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore']
  }).trim();
} catch (_) {
  workspaceRoot = process.cwd();
}
// Canonicalize both slug and hash from realpathSync so they match the broker.
// If realpathSync fails, propagate the error rather than silently using a
// non-canonical path that would produce the wrong hash and a permanent miss.
let canonicalRoot;
try { canonicalRoot = fs.realpathSync(workspaceRoot); }
catch (e) {
  process.stderr.write('disk_state_fallback: realpathSync failed: ' + e.message + '\n');
  process.exit(1);
}
// Canonicalize pluginData and verify containment (guards against '..' in CLAUDE_PLUGIN_DATA).
let canonicalPluginData;
try { canonicalPluginData = fs.realpathSync(pluginData); }
catch (e) {
  process.stderr.write('disk_state_fallback: CLAUDE_PLUGIN_DATA canonicalization failed: ' + e.message + '\n');
  process.exit(1);
}
const slugSource = path.basename(canonicalRoot) || 'workspace';
const slug = slugSource.replace(/[^a-zA-Z0-9._-]+/g, '-').replace(/^-+|-+\$/g, '') || 'workspace';
const hash = crypto.createHash('sha256').update(canonicalRoot).digest('hex').slice(0, 16);
const resolvedStateDir = path.join(canonicalPluginData, 'state', slug + '-' + hash);
// Containment check: ensure the computed path lives within canonicalPluginData.
if (!resolvedStateDir.startsWith(canonicalPluginData + path.sep) &&
    resolvedStateDir !== canonicalPluginData) {
  process.stderr.write('disk_state_fallback: state dir escaped plugin data root\n');
  process.exit(1);
}
process.stdout.write(resolvedStateDir);
" -- "$CLAUDE_PLUGIN_DATA") || return 1

  # Hard-stop: resolved path must be absolute (defense in depth after Node check).
  case "$state_dir" in
    /*) ;;
    *)  return 1 ;;
  esac

  local state_file="$state_dir/state.json"

  # Read 1: state.json — check whether jobId is listed in jobs[].
  # Distinguish absent (ENOENT — silent miss) from present-but-unreadable
  # (EACCES/EIO — emit a diagnostic so operators can distinguish the two cases).
  if [ -e "$state_file" ] && [ ! -r "$state_file" ]; then
    printf 'await: failed to read state.json at %s (permission denied); treating as miss\n' \
      "$state_file" >&2
  fi
  local state_json
  if ! state_json=$(cat "$state_file" 2>/dev/null); then
    return 1  # state.json absent or unreadable
  fi

  local job_listed
  job_listed=$(printf '%s' "$state_json" | node -e "
let chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const jobId = process.argv[1];
  let state;
  try { state = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch (e) {
    process.stderr.write('disk_state_fallback: state.json parse error: ' + e.message + '\n');
    process.exit(1);
  }
  if (!Array.isArray(state.jobs)) {
    process.stderr.write('disk_state_fallback: state.json jobs field is not an array\n');
    process.exit(1);
  }
  process.stdout.write(state.jobs.some(j => j.id === jobId) ? '1' : '0');
});
" -- "$job_id") || return 1

  if [ "$job_listed" != "1" ]; then
    return 1  # jobId absent from state.json jobs[]
  fi

  # Read 2: jobs/<jobId>.json — load and parse the per-job record.
  local job_file="$state_dir/jobs/$job_id.json"
  # Distinguish absent from present-but-unreadable (same pattern as state.json above).
  if [ -e "$job_file" ] && [ ! -r "$job_file" ]; then
    printf 'await: failed to read jobs/%s.json at %s (permission denied); treating as miss\n' \
      "$job_id" "$job_file" >&2
  fi
  local job_json
  if ! job_json=$(cat "$job_file" 2>/dev/null); then
    return 1  # per-job file absent or unreadable
  fi

  # Apply the result-fallback chain to the disk-loaded record, mirroring the
  # five-source chain used by fetch_result for broker-served records.
  #
  # Read the job's lifecycle status first so _status_to_exit_code can map it
  # to the correct exit code when no output payload is extractable.
  local job_status
  job_status=$(extract_json_field "$job_json" "status") || job_status=""
  local raw
  # (a) result.rawOutput
  if raw=$(extract_json_field "$job_json" "result.rawOutput") && [ -n "$raw" ]; then
    _emit_recovery_note "$job_id"
    printf '%s' "$raw"
    return 0
  fi
  # (b) result.codex.stdout
  if raw=$(extract_json_field "$job_json" "result.codex.stdout") && [ -n "$raw" ]; then
    _emit_recovery_note "$job_id"
    printf '%s' "$raw"
    return 0
  fi
  # (c) rendered
  if raw=$(extract_json_field "$job_json" "rendered") && [ -n "$raw" ]; then
    _emit_recovery_note "$job_id"
    printf '%s' "$raw"
    return 0
  fi
  # (d) errorMessage — job failed/cancelled with an error payload but no output.
  # Emit to stderr (not stdout) so the caller can surface it as a diagnostic.
  # Use _status_to_exit_code for the exit code: single source of truth for the
  # status → exit mapping shared with the broker-served terminal branch.
  if raw=$(extract_json_field "$job_json" "errorMessage") && [ -n "$raw" ]; then
    printf '%s\n' "$raw" >&2
    _status_to_exit_code "$job_status"
    return $?
  fi

  # No extractable output from any source.  Map status → exit code so that
  # cancelled/failed disk records with no payload still diverge from a plain
  # miss (exit 1) rather than silently returning not-found (exit 11).
  _status_to_exit_code "$job_status"
  return $?
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
        # "completed:<terminal>"; extract the terminal sub-status so that
        # _status_to_exit_code can produce the correct exit code when
        # fetch_result returns an unexpected error (single source of truth).
        local terminal_status="${outcome#completed:}"
        local res_rc=0
        if fetch_result "$companion" "$job_id"; then
          final_rc=0
        else
          res_rc=$?
          case "$res_rc" in
            11) final_rc=11 ;;
            14) final_rc=14 ;;
            *)
              # Use _status_to_exit_code so the broker-served hard-error exit
              # shares the same status → exit mapping as disk_state_fallback.
              _status_to_exit_code "$terminal_status"; final_rc=$?
              # _status_to_exit_code returns 1 for unknown statuses; map that
              # to the public hard-error exit (13) to preserve existing behavior.
              [ "$final_rc" -eq 1 ] && final_rc=13
              ;;
          esac
        fi
        break
        ;;
      not-found)
        # Consult the broker's on-disk state before taking the terminal
        # not-found exit.  disk_state_fallback reads at most 2 files per call
        # and is invoked only from this branch (phase-fallback and launch-verify
        # branches are untouched).
        local disk_rc
        disk_state_fallback "$job_id"; disk_rc=$?
        case "$disk_rc" in
          0)
            # Successful disk recovery: output already written to stdout,
            # recovery note already emitted to stderr.
            final_rc=0
            ;;
          13)
            # Job found on disk, status failed/cancelled; diagnostic already
            # emitted to stderr by disk_state_fallback via _status_to_exit_code.
            final_rc=13
            ;;
          14)
            # Job found on disk, status completed but no extractable output;
            # treat as malformed (mirrors broker-served fetch_result rc=14).
            final_rc=14
            ;;
          *)
            # Miss (disk_rc=1) or other: take the existing terminal not-found
            # exit unchanged.
            final_rc=11
            printf 'await: job %s not found by companion\n' "$job_id" >&2
            ;;
        esac
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
