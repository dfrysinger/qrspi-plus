#!/usr/bin/env bash
# codex-companion-bg.sh — non-blocking wrapper around codex-companion.mjs.
#
# Subcommands:
#   launch --prompt-file <path>   Fork companion `task --background` and print
#                                 the captured jobId; exit 0 within ~5s.
#   await <jobId>                 Poll status (5s/30s with backoff at 120s),
#                                 fetch result on completion, write review
#                                 markdown to stdout; ceiling at 1200s.
#
# Exit codes:
#   0   success
#   1   generic / launch failures
#   10  await ceiling hit
#   11  await: job-not-found
#   12  audit-log integrity failure (write/lock/perm)
#   13  await: status/result hard error or launch bad JSON
#   14  await: malformed JSON from status/result
#
# Lock primitive: `mkdir <lockdir>` is atomic on POSIX and portable to macOS
# (no flock(1)). Audit rows are well under PIPE_BUF (4096), so POSIX guarantees
# `O_APPEND` writes are atomic — the mkdir lock is defense-in-depth.

set -u
# NOT -e: we inspect non-zero rcs from subprocesses (status legitimately exits
# 1 to signal job-not-found). pipefail is similarly off.

: "${QRSPI_CODEX_POLL_INTERVAL_FAST:=5}"
: "${QRSPI_CODEX_POLL_INTERVAL_SLOW:=30}"
: "${QRSPI_CODEX_POLL_BACKOFF_AFTER:=120}"
: "${QRSPI_CODEX_CEILING_SECONDS:=1200}"
: "${QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS:=5}"

# Audit-path lockdown (R1 Codex-S2 / task-29): the audit dir, file, and lock
# names are NOT environment-overridable. The dir is resolved at runtime from
# .qrspi/state.json's `artifact_dir` field via resolve_audit_dir() — there is
# no env-var escape hatch. Any attacker-controlled $QRSPI_AUDIT_DIR /
# $QRSPI_AUDIT_FILE / $QRSPI_AUDIT_LOCK_DIR they may inject is ignored.
readonly QRSPI_AUDIT_FILENAME="audit-codex-review.jsonl"
readonly QRSPI_AUDIT_LOCK_NAME="audit-codex-review.lock"
readonly QRSPI_STATE_FILE_REL=".qrspi/state.json"

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

# ---------------------------------------------------------------------------
# Cross-platform mtime epoch for a path. macOS: stat -f %m; Linux: stat -c %Y.
file_mtime_epoch() {
  local path="$1"
  local m
  m=$(stat -f %m "$path" 2>/dev/null) || m=$(stat -c %Y "$path" 2>/dev/null) || return 1
  printf '%s' "$m"
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
# resolve_audit_dir
#
# Audit-path lockdown (R1 Codex-S2 / task-29). The audit dir is NOT
# environment-overridable. We resolve it from <CWD>/.qrspi/state.json's
# `artifact_dir` field (which the QRSPI hooks write as an absolute path), then
# canonicalize via `realpath` so any symlink in the artifact_dir chain is
# resolved to its real on-disk path BEFORE we open files for append.
#
# Fail-closed contract: state.json missing, unparseable, or lacking
# artifact_dir → rc=12 with stderr; the caller MUST refuse to write any audit
# rows. This is the security-critical property — there is no fallback to a
# CWD-relative `.qrspi/` default and no env-var escape hatch.
#
# Echoes the canonicalized audit dir (`<realpath(artifact_dir)>/.qrspi`) on
# stdout on success. On failure, returns 12 with no stdout.
resolve_audit_dir() {
  local state_file="$QRSPI_STATE_FILE_REL"
  if [ ! -f "$state_file" ]; then
    printf 'codex-companion-bg: %s not found; cannot resolve audit dir (refusing to write audit rows)\n' \
      "$state_file" >&2
    return 12
  fi

  # `jq -r` echoes a literal "null" for missing keys; guard with `// empty` so
  # the absence is observable as an empty string. A jq parse failure (rc != 0)
  # surfaces a separate error path so we don't silently treat malformed JSON
  # as "no artifact_dir."
  local artifact_dir jq_err
  if ! artifact_dir=$(jq -r '.artifact_dir // empty' < "$state_file" 2>/dev/null); then
    jq_err=$(jq -r '.artifact_dir // empty' < "$state_file" 2>&1 1>/dev/null)
    printf 'codex-companion-bg: failed to parse %s: %s\n' "$state_file" "$jq_err" >&2
    return 12
  fi
  if [ -z "$artifact_dir" ]; then
    printf 'codex-companion-bg: %s missing artifact_dir field; refusing to write audit rows\n' \
      "$state_file" >&2
    return 12
  fi
  if [ ! -d "$artifact_dir" ]; then
    printf 'codex-companion-bg: artifact_dir from state.json is not a directory: %s\n' \
      "$artifact_dir" >&2
    return 12
  fi

  # `realpath` canonicalizes every component (resolving any symlinks in the
  # ancestor chain). On macOS `/tmp` resolves to `/private/tmp`, so callers
  # comparing paths must compare canonicalized forms (we always do).
  local canon
  if ! canon=$(realpath "$artifact_dir" 2>/dev/null); then
    printf 'codex-companion-bg: realpath failed for artifact_dir %s\n' "$artifact_dir" >&2
    return 12
  fi
  if [ -z "$canon" ]; then
    printf 'codex-companion-bg: realpath returned empty for artifact_dir %s\n' "$artifact_dir" >&2
    return 12
  fi
  printf '%s/.qrspi' "$canon"
}

# ---------------------------------------------------------------------------
# emit_audit_row job_id elapsed_seconds completion_status timestamp
#
# Append one JSONL row to <artifact_dir>/.qrspi/audit-codex-review.jsonl,
# where <artifact_dir> is resolved from state.json (NOT from any env var).
# Acquires mkdir-lock with bounded retry; reaps locks older than 30s via
# cross-platform stat. Returns 0 on success, 12 on any integrity failure
# (state-resolve, perm, symlink, lock leak, append).
emit_audit_row() {
  local job_id="$1" elapsed="$2" status="$3" ts="$4"

  # Resolve audit dir from state.json (security-critical: no env override).
  # Any failure here is a hard 12 — we refuse to write to a fallback CWD
  # `.qrspi/` because that would mask the missing-state condition the
  # security spec demands we surface.
  local audit_dir
  if ! audit_dir=$(resolve_audit_dir); then
    return 12
  fi
  local audit_file="$audit_dir/$QRSPI_AUDIT_FILENAME"
  local lock_dir="$audit_dir/$QRSPI_AUDIT_LOCK_NAME"

  # Spec line 14: audit dir must be 0700. Create it if missing; if it already
  # exists with looser perms, repair via chmod — and HARD FAIL if chmod fails
  # (silent-failure C2). Do not silently honor an insecure dir.
  if [ ! -d "$audit_dir" ]; then
    if ! mkdir -m 0700 "$audit_dir" 2>/dev/null; then
      printf 'codex-companion-bg: could not create audit dir %s\n' "$audit_dir" >&2
      return 12
    fi
  else
    local chmod_err
    chmod_err=$(chmod 0700 "$audit_dir" 2>&1) || {
      printf 'codex-companion-bg: audit dir %s exists with insecure permissions; chmod 0700 failed: %s\n' \
        "$audit_dir" "$chmod_err" >&2
      return 12
    }
  fi

  # Acquire mkdir-lock with bounded retry (~10s under heavy contention).
  # Stale-reap: if existing lockdir is older than 30s, treat as crashed-writer
  # leftover and remove it. Uses cross-platform stat (BSD `find -mmin +0.5` is
  # unsupported on macOS — would silently return nothing → wedge).
  local attempts=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ -d "$lock_dir" ]; then
      local lock_mtime current age
      if lock_mtime=$(file_mtime_epoch "$lock_dir") && current=$(now_epoch); then
        age=$((current - lock_mtime))
        if [ "$age" -gt 30 ]; then
          if ! rmdir "$lock_dir" 2>/dev/null; then
            if ! rm -rf "$lock_dir" 2>/dev/null; then
              printf 'codex-companion-bg: could not reap stale lockdir %s (age=%ds)\n' \
                "$lock_dir" "$age" >&2
            fi
          fi
        fi
      fi
    fi
    if [ "$attempts" -gt 400 ]; then
      printf 'codex-companion-bg: failed to acquire audit lock after %d attempts\n' "$attempts" >&2
      return 12
    fi
    sleep 0.05
  done

  # Build JSON via jq (handles control chars / quotes / backslashes correctly).
  # jq is already a hard dependency for the bats suite and downstream callers.
  local row
  if ! row=$(jq -nc \
      --arg job_id "$job_id" \
      --argjson elapsed "$elapsed" \
      --arg status "$status" \
      --arg ts "$ts" \
      '{job_id:$job_id, elapsed_seconds:$elapsed, completion_status:$status, timestamp:$ts}'); then
    rmdir "$lock_dir" 2>/dev/null
    printf 'codex-companion-bg: failed to encode audit JSON via jq\n' >&2
    return 12
  fi

  # PIPE_BUF guard: POSIX guarantees `O_APPEND` writes ≤ PIPE_BUF (4096 bytes
  # on Linux/macOS) are atomic — the foundation of the lock-free concurrency
  # property. The mkdir lock is defense-in-depth, not a serialization layer
  # for arbitrarily large rows. If the row plus its trailing newline exceeds
  # 4096 bytes we fail-closed: silently truncating or interleaving would
  # break the per-row JSONL invariant downstream consumers depend on.
  #
  # [CodexF2-resolved] Use `wc -c` for a true BYTE count rather than bash's
  # ${#row}, which counts CHARACTERS in the active locale. In UTF-8 locales
  # a multibyte char (e.g. a 4-byte emoji) counts as 1 in ${#row} but as 4
  # bytes against PIPE_BUF, so a row with multibyte content could pass the
  # char-check while exceeding 4096 actual bytes on append. printf '%s\n'
  # adds the trailing newline so wc's count equals what we will write.
  local row_len
  row_len=$(printf '%s\n' "$row" | wc -c)
  row_len=${row_len//[[:space:]]/}   # wc -c on macOS prefixes spaces
  if [ "$row_len" -gt 4096 ]; then
    rmdir "$lock_dir" 2>/dev/null
    printf 'codex-companion-bg: audit row would be %d bytes (>4096 PIPE_BUF cap); refusing to append\n' \
      "$row_len" >&2
    return 12
  fi

  # Symlink lockdown (R1 Codex-S2 / task-29). If the audit-file path itself is
  # a symlink, refuse to follow it — an attacker could plant a symlink at
  # <audit_dir>/audit-codex-review.jsonl pointing at /etc/passwd or a sibling
  # workspace's secrets file, and a naive `>>` append would dereference it and
  # corrupt that target. We use `[ -L ... ]` (lstat semantics) AFTER taking
  # the mkdir lock so the check is race-free against concurrent writers in
  # this process group; cross-process attackers planting between this check
  # and the append are bounded by the directory's 0700 perm we just enforced.
  if [ -L "$audit_file" ]; then
    rmdir "$lock_dir" 2>/dev/null
    printf 'codex-companion-bg: audit file %s is a symlink; refusing to follow (path-injection guard)\n' \
      "$audit_file" >&2
    return 12
  fi

  # Capture append stderr so errno survives — never silently lose failure cause.
  local append_err
  if ! append_err=$(printf '%s\n' "$row" 2>&1 >>"$audit_file"); then
    rmdir "$lock_dir" 2>/dev/null
    printf 'codex-companion-bg: audit append failed for %s: %s\n' "$audit_file" "$append_err" >&2
    return 12
  fi

  # Lock release on the success path. If rmdir fails, the lock is leaked and
  # the next writer will block until stale-reap (≥30s wait) — surface as a
  # hard integrity failure rather than pretending success.
  if ! rmdir "$lock_dir" 2>/dev/null; then
    printf 'codex-companion-bg: lock release failed for %s (lock leaked)\n' "$lock_dir" >&2
    return 12
  fi
  return 0
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
launch_subcommand() {
  local prompt_file=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --prompt-file)
        if [ "$#" -lt 2 ]; then
          printf 'launch: --prompt-file requires a value\n' >&2
          return 1
        fi
        prompt_file="$2"
        shift 2
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
# The `completed:<terminal>` form lets await_subcommand record the real terminal
# status in its audit row without re-invoking `node ... status` a second time
# (one fewer subprocess per terminal job).
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
await_subcommand() {
  if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    printf 'await: jobId argument is required\n' >&2
    return 1
  fi
  local job_id="$1"

  local companion
  if ! companion=$(resolve_codex_companion); then
    # Distinguish infrastructure failure (no companion installed) from
    # malformed (companion returned bad JSON). Audit row still emitted so the
    # caller's log isn't silent.
    local ts
    ts=$(now_iso) || ts="1970-01-01T00:00:00Z"
    if ! emit_audit_row "$job_id" 0 "infrastructure-failure" "$ts"; then
      printf 'await: audit-row write failed during infrastructure-failure path for job %s\n' "$job_id" >&2
      return 12
    fi
    return 1
  fi

  local start_epoch
  start_epoch=$(now_epoch) || return 1
  local ceiling="$QRSPI_CODEX_CEILING_SECONDS"
  local backoff_after="$QRSPI_CODEX_POLL_BACKOFF_AFTER"
  local fast_int="$QRSPI_CODEX_POLL_INTERVAL_FAST"
  local slow_int="$QRSPI_CODEX_POLL_INTERVAL_SLOW"

  local final_status=""
  local final_rc=0

  while :; do
    local now_e elapsed
    now_e=$(now_epoch) || return 1
    elapsed=$((now_e - start_epoch))

    if [ "$elapsed" -ge "$ceiling" ]; then
      final_status="ceiling-hit"
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
        # "completed:<terminal>" so we don't need a second `node ... status`
        # subprocess to learn whether the job ended successful/failed/cancelled.
        local terminal_status="${outcome#completed:}"

        local res_rc=0
        if fetch_result "$companion" "$job_id"; then
          case "$terminal_status" in
            failed)    final_status="failed" ;;
            cancelled) final_status="cancelled" ;;
            *)         final_status="success" ;;
          esac
          final_rc=0
        else
          res_rc=$?
          case "$res_rc" in
            11) final_status="job-not-found"; final_rc=11 ;;
            14) final_status="malformed";     final_rc=14 ;;
            *)  final_status="malformed";     final_rc=13 ;;
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

  local end_epoch elapsed_total
  end_epoch=$(now_epoch) || return 1
  elapsed_total=$((end_epoch - start_epoch))

  local ts
  ts=$(now_iso) || return 1

  if ! emit_audit_row "$job_id" "$elapsed_total" "$final_status" "$ts"; then
    printf 'await: audit-row write failed for job %s\n' "$job_id" >&2
    return 12
  fi

  return "$final_rc"
}

# ---------------------------------------------------------------------------
main() {
  if [ "$#" -lt 1 ]; then
    cat >&2 <<'USAGE'
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
