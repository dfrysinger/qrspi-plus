#!/usr/bin/env bash
set -euo pipefail

# Source frontmatter.sh and artifact-map.sh from the same directory
# Use a more robust method that works in all contexts
_state_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_state_script_dir/frontmatter.sh"
source "$_state_script_dir/artifact-map.sh"

# ---------------------------------------------------------------------------
# T24 — current_step allowlist
#
# Allowlist = the 9 file-backed pipeline steps emitted by the hook layer
# (goals, questions, research, design, phasing, structure, plan, implement,
# test) PLUS the 3 transition states documented in
# skills/using-qrspi/SKILL.md:223 (parallelize, integrate, replan). External
# writers (Implement, Replan) persist transition states even though
# state_compute_current_step never emits them. Any value outside this 12-value
# set is rejected fail-closed by state_write_atomic.
# ---------------------------------------------------------------------------
_state_current_step_is_allowed() {
  local v="$1"
  case "$v" in
    goals|questions|research|design|phasing|structure|plan|parallelize|implement|integrate|test|replan)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# T24 — file lock for state_write_atomic (R2 S-N4)
#
# Rationale: serializes the read-modify-write critical section against
# concurrent callers (Plan's narrow direct write vs PostToolUse hook
# reconciliation). Two implementations are layered:
#
#  Primary: flock(1) on .qrspi/state.json.lock — used when flock is on PATH
#           (Linux, *BSD, and macOS systems with util-linux/flock installed).
#           This is the spec-mandated mechanism for finding R2 S-N4.
#  Fallback: mkdir-based mutex on the same lock dir path — used on macOS
#           (where flock(1) is absent by default) and any other platform
#           lacking flock. mkdir is atomic on POSIX. Stale-lock detection
#           via PID file (kill -0) and epoch file (30s wallclock) prevents
#           deadlock if a holder crashes.
#
# Lock target: .qrspi/state.json.lock
#   - When flock is used, this is a regular file opened on FD 9.
#   - When mkdir-mutex is used, this is a directory containing owner.pid
#     and started.epoch.
#   The two implementations cannot interoperate on the same host (a flock'd
#   file vs an mkdir'd directory differ in inode type), but every caller
#   on a given host uses the same primitive (chosen at function-call time
#   by `command -v flock`), so consistency is preserved within the host.
#
# Acquire timeout: 10 s.
# Stale timeout (mkdir fallback only): 30 s.
# ---------------------------------------------------------------------------

# Module-level: detect flock once. We re-check each call (cheap) so test
# environments that PATH-stub flock get the right behavior.
_state_have_flock() {
  command -v flock >/dev/null 2>&1
}

# _state_lock_acquire — primary entry. Dispatches to flock or mkdir-mutex.
# Sets _STATE_LOCK_KIND ("flock" | "mkdir") for _state_lock_release to know
# which release path to take.
_state_lock_acquire() {
  if _state_have_flock; then
    _state_lock_acquire_flock
  else
    _state_lock_acquire_mkdir
  fi
}

_state_lock_release() {
  case "${_STATE_LOCK_KIND:-}" in
    flock) _state_lock_release_flock ;;
    mkdir) _state_lock_release_mkdir ;;
    *) : ;;  # No lock held (or unknown kind); release is a no-op
  esac
  _STATE_LOCK_KIND=""
}

# ---- flock implementation (primary) ----
#
# Symlink-clobber defense (T24 R2 sec finding 1, R3 sec finding 1):
# An attacker with write access to `.qrspi/` could pre-place
# `.qrspi/state.json.lock` as a symlink to an attacker-chosen writable
# target (e.g., ~/.ssh/authorized_keys). With `> "$lock_file"` (truncate),
# that target gets clobbered before any locking occurs. Round-2 added
# detect-and-remove, but a TOCTOU window remained between the check and
# the redirect.
#
# Round-3 fix: switch from truncate (`>`) to append (`>>`). Append never
# truncates the file, so even if a symlink races back into the path
# between the symlink check and the open, no clobber occurs. flock(1)
# operates on the file descriptor's inode regardless of the file's
# content, so append vs truncate is irrelevant for locking semantics.
# We still detect-and-remove a pre-existing symlink (defense in depth)
# but no longer rely on a post-touch re-check.
_state_lock_acquire_flock() {
  local lock_file=".qrspi/state.json.lock"

  # Symlink defense (defense in depth — main protection is open-as-append below).
  if [[ -L "$lock_file" ]]; then
    if ! rm -f "$lock_file" 2>/dev/null; then
      echo "state_lock: refused to use $lock_file — pre-existing symlink that cannot be removed" >&2
      return 1
    fi
  fi

  # Open lock file on FD 9 in APPEND mode (no truncation). flock works on
  # the FD inode, not file content, so append is sufficient and eliminates
  # the symlink-clobber primitive.
  exec 9>>"$lock_file" || {
    echo "state_lock: failed to open lock file $lock_file on FD 9" >&2
    return 1
  }
  if ! flock -w 10 9 2>/dev/null; then
    echo "state_lock: failed to acquire flock on $lock_file within 10s" >&2
    exec 9>&- 2>/dev/null || true
    return 1
  fi
  _STATE_LOCK_KIND="flock"
  return 0
}

_state_lock_release_flock() {
  # Closing FD 9 releases the flock. Best-effort cleanup of lock file
  # (other waiters may still hold the FD; rm is fine — flock is per-FD,
  # not per-path).
  exec 9>&- 2>/dev/null || true
}

# ---- mkdir-based mutex (fallback for macOS / no flock) ----
_state_lock_acquire_mkdir() {
  local lock_dir=".qrspi/state.json.lock"
  local pid_file="$lock_dir/owner.pid"
  local acquire_timeout=10

  local start
  start=$(date +%s)

  while true; do
    if mkdir "$lock_dir" 2>/dev/null; then
      # Acquired. Write owner.pid and FAIL CLOSED on metadata write error —
      # without owner.pid, stale-lock detection cannot tell stale from live
      # holders, so we'd silently degrade serialization. Better to release
      # and abort than degrade.
      if ! echo "$$" > "$pid_file" 2>/dev/null; then
        echo "state_lock: failed to write owner.pid in $lock_dir — aborting acquire" >&2
        rm -rf "$lock_dir" 2>/dev/null || true
        return 1
      fi
      _STATE_LOCK_KIND="mkdir"
      return 0
    fi

    # mkdir failed. Distinguish "lock already held" (lock_dir exists)
    # from "cannot create" (permissions, parent missing, IO error). In the
    # latter case retrying is futile — fail fast.
    if [[ ! -d "$lock_dir" ]]; then
      echo "state_lock: failed to create lock directory $lock_dir (permission denied or IO error)" >&2
      return 1
    fi

    # Lock held — check for stale owner via PID liveness only.
    # Round-3 simplifier review noted that wallclock-based stale reclaim
    # weakens correctness: a live holder paused/slow past the wallclock
    # threshold gets evicted, which exactly recreates the lost-update
    # class T24 prevents. PID liveness is correct (the holder either
    # exists or doesn't); we drop the wallclock heuristic entirely.
    # If owner.pid is unreadable, we wait out the holder rather than
    # reclaiming (silent-failure round-2 finding 4).
    local owner=""
    local owner_readable=false
    if [[ -f "$pid_file" ]]; then
      if owner=$(cat "$pid_file" 2>/dev/null); then
        owner_readable=true
      fi
    fi
    local now
    now=$(date +%s)

    if $owner_readable && [[ -n "$owner" ]] && [[ "$owner" =~ ^[0-9]+$ ]] && ! kill -0 "$owner" 2>/dev/null; then
      # Stale: owner PID is dead. Reclaim and retry.
      rm -rf "$lock_dir" 2>/dev/null || true
      continue
    fi

    # Bounded wait
    if (( now - start > acquire_timeout )); then
      local owner_str="$owner"
      [[ -z "$owner_str" ]] && owner_str="<owner.pid unreadable>"
      echo "state_lock: failed to acquire lock $lock_dir within ${acquire_timeout}s (held by PID $owner_str)" >&2
      return 1
    fi
    # Brief sleep to avoid busy spin
    sleep 0.05 2>/dev/null || sleep 1
  done
}

_state_lock_release_mkdir() {
  local lock_dir=".qrspi/state.json.lock"
  rm -rf "$lock_dir" 2>/dev/null || true
}

# state_compute_current_step <artifact_dir>
# Helper: scan artifact files in <artifact_dir>, determine the first pipeline step
# whose artifact frontmatter is not "approved", and echo that step name.
# Only the 8 file-backed steps (goals, questions, research, design, phasing,
# structure, plan, parallelize) are inspected. If all 8 are approved, echoes
# "implement" (the first non-file-backed step, which defaults to "draft"). This
# matches state_init_or_reconcile, where implement is the next step in pipeline
# order after parallelize-approved.
# Returns 1 if artifact_dir does not exist.
#
# Single source of truth for the "first non-approved step" computation.
# state_init_or_reconcile delegates here (FU-1 refactor 2026-04-28; T25 added
# parallelize as the 8th file-backed step).
state_compute_current_step() {
  local artifact_dir="$1"
  [[ -d "$artifact_dir" ]] || return 1

  local _step _artifact_file _status
  for _step in goals questions research design phasing structure plan parallelize; do
    _artifact_file="$artifact_dir/$(artifact_map_get "$_step")"
    _status="draft"
    if [[ -f "$_artifact_file" ]]; then
      if ! _status=$(frontmatter_get_status "$_artifact_file" 2>/dev/null); then
        _status="draft"
      fi
    fi
    if [[ "$_status" != "approved" ]]; then
      echo "$_step"
      return 0
    fi
  done

  # implement and test are never inferred from files; default to "implement" if
  # all 8 file-backed steps are approved (matches state_init_or_reconcile: the
  # next step after parallelize-approved is implement, since implement is also
  # "draft" by default and is the first non-approved step in pipeline order).
  echo "implement"
}

# state_init_or_reconcile <artifact_dir>
# Scans artifact files in the given directory, reads their frontmatter status,
# and creates/updates .qrspi/state.json in the current working directory.
#
# T24 update (R2 I-N3): preserves an existing non-null phase_start_commit
# rather than wiping it on every call. Plan's narrow-direct-write must
# survive subsequent reconciliation.
state_init_or_reconcile() {
  local artifact_dir="$1"

  # Check if artifact_dir exists
  [[ -d "$artifact_dir" ]] || return 1

  # Determine statuses for all 10 artifacts (M54 added phasing between design and structure;
  # T25 R2 I-N4 added parallelize between plan and implement)
  local goals_status="draft"
  local questions_status="draft"
  local research_status="draft"
  local design_status="draft"
  local phasing_status="draft"
  local structure_status="draft"
  local plan_status="draft"
  local parallelize_status="draft"
  local implement_status="draft"
  local test_status="draft"

  # Check each artifact file using canonical mapping
  local _step _artifact_file
  for _step in goals questions research design phasing structure plan parallelize; do
    _artifact_file="$artifact_dir/$(artifact_map_get "$_step")"
    if [[ -f "$_artifact_file" ]]; then
      local _read_status
      if ! _read_status=$(frontmatter_get_status "$_artifact_file"); then
        echo "WARNING: cannot read status from $_artifact_file, defaulting to draft" >&2
        _read_status="draft"
      fi
      eval "${_step}_status=\$_read_status"
    fi
  done

  # implement and test are never read from files, always draft unless inferred
  # (but for now we keep them as draft)

  # Determine current_step: delegate to state_compute_current_step (FU-1
  # refactor 2026-04-28). state_compute_current_step is the single source of
  # truth for the "first non-approved step" computation, so any pipeline-order
  # change requires touching exactly one call site (the helper itself).
  local current_step
  if ! current_step=$(state_compute_current_step "$artifact_dir"); then
    echo "state_init_or_reconcile: state_compute_current_step failed" >&2
    return 1
  fi

  # T24-A4: defense-in-depth — validate delegated helper return value before
  # serialization. If state_compute_current_step is shadowed/mutated to
  # return a value outside the allowlist, fail closed.
  if ! _state_current_step_is_allowed "$current_step"; then
    echo "state_init_or_reconcile: state_compute_current_step returned out-of-allowlist value '$current_step'" >&2
    return 1
  fi

  # Create absolute path for artifact_dir
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$artifact_dir" && pwd)"

  # T24 round-2 spec finding: phase_start_commit read AND the rebuild+write
  # MUST happen under the same lock as state_update, otherwise a
  # state_update writer can commit a newer phase_start_commit between our
  # read and our write, and we will overwrite it with a stale value.
  # Acquire the shared lock here for the entire R-M-W critical section.
  if ! mkdir -p ".qrspi" 2>/dev/null; then
    echo "state_init_or_reconcile: failed to create .qrspi directory" >&2
    return 1
  fi
  if ! _state_lock_acquire; then
    echo "state_init_or_reconcile: failed to acquire state lock" >&2
    return 1
  fi

  # Read existing phase_start_commit under lock (R2 I-N3 + spec round-2 fix).
  # Fail CLOSED on corrupt state.json: silent-failure round-2 finding 2 noted
  # that masking jq parse errors as empty silently destroys phase_start_commit.
  # Better to abort and surface the corruption than overwrite a value we
  # cannot read.
  local phase_start_commit_arg=""
  if [[ -f ".qrspi/state.json" ]]; then
    local existing_state
    if ! existing_state=$(cat ".qrspi/state.json" 2>/dev/null); then
      echo "state_init_or_reconcile: failed to read existing .qrspi/state.json under lock" >&2
      _state_lock_release
      return 1
    fi
    # If the existing state is non-empty, parse it. An empty file is treated
    # as "no prior state" (initialization case).
    if [[ -n "$existing_state" ]]; then
      local existing_psc
      if ! existing_psc=$(echo "$existing_state" | jq -r '.phase_start_commit // ""' 2>/dev/null); then
        echo "state_init_or_reconcile: existing .qrspi/state.json is corrupt (jq parse failed) — refusing to overwrite" >&2
        _state_lock_release
        return 1
      fi
      if [[ -n "$existing_psc" && "$existing_psc" != "null" ]]; then
        phase_start_commit_arg="$existing_psc"
      fi
    fi
  fi

  # Create the state JSON (compact format).
  # T24-B: phase_start_commit is conditionally preserved. We pass either
  # null (when no prior value) or the carried-forward string via an
  # explicit jq filter that converts "" sentinel to null.
  local json
  if ! json=$(jq -cn \
    --arg current_step "$current_step" \
    --arg artifact_dir "$abs_artifact_dir" \
    --arg phase_start_commit "$phase_start_commit_arg" \
    --arg goals "$goals_status" \
    --arg questions "$questions_status" \
    --arg research "$research_status" \
    --arg design "$design_status" \
    --arg phasing "$phasing_status" \
    --arg structure "$structure_status" \
    --arg plan "$plan_status" \
    --arg parallelize "$parallelize_status" \
    --arg implement "$implement_status" \
    --arg test "$test_status" \
    '{
      version: 1,
      current_step: $current_step,
      phase_start_commit: (if $phase_start_commit == "" then null else $phase_start_commit end),
      artifact_dir: $artifact_dir,
      wireframe_requested: false,
      artifacts: {
        goals: $goals,
        questions: $questions,
        research: $research,
        design: $design,
        phasing: $phasing,
        structure: $structure,
        plan: $plan,
        parallelize: $parallelize,
        implement: $implement,
        test: $test
      }
    }'); then
    echo "state_init_or_reconcile: jq failed to build state JSON" >&2
    _state_lock_release
    return 1
  fi

  if [[ -z "$json" ]]; then
    echo "state_init_or_reconcile: jq failed — empty output" >&2
    _state_lock_release
    return 1
  fi

  # Validate output is well-formed JSON before writing (basic structural check)
  local trimmed
  trimmed="${json#"${json%%[![:space:]]*}"}"
  if [[ "${trimmed:0:1}" != "{" ]] || [[ "${trimmed: -1}" != "}" ]]; then
    echo "state_init_or_reconcile: jq produced invalid JSON" >&2
    _state_lock_release
    return 1
  fi
  if [[ "$json" != *'"version"'* ]]; then
    echo "state_init_or_reconcile: jq produced JSON missing required fields" >&2
    _state_lock_release
    return 1
  fi

  # Inline write under the existing lock (bypass state_write_atomic to avoid
  # double-acquire). _state_write_inline_locked validates current_step and
  # does the temp-file + atomic mv.
  if ! _state_write_inline_locked "$json"; then
    echo "state_init_or_reconcile: locked write failed" >&2
    _state_lock_release
    return 1
  fi

  _state_lock_release
  return 0
}

# state_update <jq_filter> [--arg KEY VALUE | --argjson KEY VALUE]...
# Atomic read-modify-write of .qrspi/state.json under the lock that
# state_write_atomic uses. Reads the current state, applies <jq_filter>
# (a jq expression operating on the state JSON), validates the resulting
# current_step against the allowlist, and writes the result. The entire
# critical section is serialized against any other state_update or
# state_write_atomic caller.
#
# This is the spec-mandated path (R2 S-N4 option 2) for callers that need
# to mutate a single field without losing concurrent updates to other
# fields. Callers like Plan's narrow-direct-write should use this rather
# than read+modify+state_write_atomic, which leaves the R-M-W window
# unserialized.
#
# Filter parameters: callers SHOULD bind untrusted values via `--arg
# KEY VALUE` (string) or `--argjson KEY VALUE` (already-JSON value, e.g.
# booleans, arrays, numbers). The variadic args after the filter are
# forwarded verbatim to jq. This avoids caller-side jq-filter string
# interpolation of untrusted data — the filter itself stays as a static
# jq expression, and parameters are jq-typed at the parser level.
#
# Examples:
#   state_update '.phase_start_commit = "abc123"'
#   state_update '.artifacts[$step] = "approved"' --arg step "$step"
#   state_update '.wireframe_requested = $w' --argjson w true
#   state_update 'reduce $steps[] as $s (.; .artifacts[$s] = "draft")' \
#     --argjson steps '["plan","parallelize","implement","test"]'
#
# Returns:
#   0 on success
#   1 on lock acquire failure, jq error, or write error (with stderr diagnostic)
state_update() {
  local filter="$1"
  shift

  # Validate variadic args: only --arg KEY VALUE or --argjson KEY VALUE
  # forms are accepted. Each consumes 3 tokens. Reject anything else
  # fail-closed so a typo can't silently bypass jq parameter binding.
  local jq_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --arg|--argjson)
        if [[ $# -lt 3 ]]; then
          echo "state_update: $1 requires KEY and VALUE arguments" >&2
          return 1
        fi
        jq_args+=("$1" "$2" "$3")
        shift 3
        ;;
      *)
        echo "state_update: unknown argument '$1' (only --arg / --argjson supported)" >&2
        return 1
        ;;
    esac
  done

  # Acquire lock for the entire R-M-W critical section.
  if ! mkdir -p ".qrspi" 2>/dev/null; then
    echo "state_update: failed to create .qrspi directory" >&2
    return 1
  fi
  if ! _state_lock_acquire; then
    return 1
  fi

  # Read current state under lock.
  local current=""
  if [[ -f ".qrspi/state.json" ]]; then
    if ! current=$(cat ".qrspi/state.json" 2>/dev/null); then
      echo "state_update: failed to read .qrspi/state.json under lock" >&2
      _state_lock_release
      return 1
    fi
  else
    echo "state_update: .qrspi/state.json does not exist (nothing to update)" >&2
    _state_lock_release
    return 1
  fi

  # Apply filter via jq, forwarding any --arg / --argjson bindings.
  # When jq_args is empty, `"${jq_args[@]+"${jq_args[@]}"}"` expands to
  # nothing under bash 3.2 + set -u (workaround for the "unbound variable"
  # error on empty-array expansion).
  local updated
  if ! updated=$(echo "$current" | jq -c ${jq_args[@]+"${jq_args[@]}"} "$filter" 2>/dev/null); then
    echo "state_update: jq filter '$filter' failed" >&2
    _state_lock_release
    return 1
  fi

  # Inline write under the existing lock (validates allowlist, temp+mv).
  if ! _state_write_inline_locked "$updated"; then
    echo "state_update: locked write failed" >&2
    _state_lock_release
    return 1
  fi

  _state_lock_release
  return 0
}

# _state_write_inline_locked <json>
# Internal helper. Caller MUST already hold the state lock. Validates
# current_step against the allowlist (T24-A) using jq for parse-correctness
# (no raw substring pre-filter — round-2 silent-failure-hunter and
# security-reviewer both flagged unicode-escape bypass `current_step`),
# then writes the JSON via temp file + atomic mv.
#
# Returns 0 on success, 1 on validation or write failure (with stderr).
_state_write_inline_locked() {
  local json="$1"

  # Structural validation (round-3 silent-failure finding 1): the payload
  # MUST be a JSON object containing a "version" field. Without this
  # check, state_update with a filter like 'null' or '{}' would commit
  # an invalid state shape — silently corrupting the state file.
  # We use `jq -e 'type == "object" and has("version")'` which exits 0
  # iff the predicate is true, non-zero (or "false" output) otherwise.
  if ! echo "$json" | jq -e 'type == "object" and has("version")' >/dev/null 2>&1; then
    echo "state_lock: payload is not a JSON object with a 'version' field (refusing to write)" >&2
    return 1
  fi

  # Allowlist validation via jq — parses JSON, extracts current_step (or
  # empty if absent/null), validates against the 12-value enum.
  # We do NOT pre-filter on raw substring: a JSON unicode escape such as
  # `"current_step"` would parse to the real key `current_step` while
  # missing a literal substring match — that bypass was confirmed by both
  # silent-failure-hunter (round-2 finding 1) and security-reviewer
  # (round-2 finding 2).
  local cs
  if ! cs=$(echo "$json" | jq -r '.current_step // empty' 2>/dev/null); then
    echo "state_lock: payload not parseable as JSON (refusing to write)" >&2
    return 1
  fi
  if [[ -n "$cs" ]] && ! _state_current_step_is_allowed "$cs"; then
    echo "state_lock: current_step '$cs' is not in the allowlist (refusing to write)" >&2
    return 1
  fi

  # Atomic write: temp file in .qrspi/ + mv into place.
  local temp_file
  if ! temp_file=$(mktemp ".qrspi/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_lock: failed to create temp file in .qrspi/" >&2
    return 1
  fi
  if ! echo "$json" > "$temp_file" 2>/dev/null; then
    echo "state_lock: failed to write to temp file $temp_file" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi
  if ! mv "$temp_file" ".qrspi/state.json" 2>/dev/null; then
    echo "state_lock: failed to move temp file to .qrspi/state.json" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi
  return 0
}

# state_read
# Outputs .qrspi/state.json on stdout, returns 0.
# Returns 1 if file doesn't exist.
state_read() {
  local state_file=".qrspi/state.json"

  if [[ -f "$state_file" ]]; then
    cat "$state_file"
    return 0
  else
    return 1
  fi
}

# state_write_atomic <json_string>
# Writes JSON to .qrspi/state.json via temp file + mv for atomicity.
# Creates .qrspi/ directory if needed.
#
# T24 hardening:
#   - R1 Codex-S3 allowlist: validates current_step (when present in payload)
#     against the 12-value documented enum. Out-of-allowlist values are
#     rejected fail-closed (non-zero exit, no write). Validation uses jq
#     parsing (not raw substring) to defeat unicode-escape bypass.
#   - R2 S-N4 TOCTOU: serializes the critical section via a portable file
#     lock in .qrspi/state.json.lock (flock when available, mkdir-mutex
#     fallback). Lock acquired before write, released on every exit path
#     (no traps — explicit release at each return point).
#
# NOTE: state_write_atomic protects only this single write against torn
# writes (atomic mv). Callers doing read-modify-write across separate
# state_read + state_write_atomic calls have an open R-M-W window between
# them and MUST use state_update instead, which performs the full R-M-W
# under the same lock.
state_write_atomic() {
  local json="$1"

  # Create .qrspi directory if needed
  if ! mkdir -p ".qrspi" 2>/dev/null; then
    echo "state_write_atomic: failed to create .qrspi directory" >&2
    return 1
  fi

  # Acquire lock
  if ! _state_lock_acquire; then
    return 1
  fi

  # Validate + write under lock
  if ! _state_write_inline_locked "$json"; then
    _state_lock_release
    return 1
  fi

  _state_lock_release
  return 0
}
