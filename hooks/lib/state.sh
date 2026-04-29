#!/usr/bin/env bash
set -euo pipefail

# Source frontmatter.sh and artifact-map.sh from the same directory
# Use a more robust method that works in all contexts
_state_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_state_script_dir/frontmatter.sh"
source "$_state_script_dir/artifact-map.sh"

# ---------------------------------------------------------------------------
# F-1: state location is rooted at <artifact_dir>/.qrspi/state.json (NOT
# PWD-relative). Every public API takes an optional trailing artifact_dir
# (default "." preserves PWD-relative legacy for callers — including
# tests — that pre-cd into the artifact directory).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# current_step allowlist
#
# Allowlist = the 8 file-backed pipeline steps emitted by
# state_compute_current_step (goals, questions, research, design, phasing,
# structure, plan, parallelize) PLUS the 4 transition states documented in
# skills/using-qrspi/SKILL.md (implement, integrate, test, replan). External
# writers (Implement, Replan) persist transition states even though
# state_compute_current_step never emits them. Any value outside this 12-value
# set is rejected fail-closed by state_write_atomic / state_update.
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
# File lock for state_write_atomic / state_update
#
# Lock path: <artifact_dir>/.qrspi/state.json.lock
#
# Two implementations are layered:
#  Primary: flock(1) — used when flock is on PATH (Linux, *BSD, macOS with
#           util-linux installed). Spec-mandated mechanism for R2 S-N4.
#  Fallback: mkdir-based mutex on the same lock dir path — used on macOS
#           (where flock(1) is absent by default) and any other platform
#           lacking flock. mkdir is atomic on POSIX. Stale-lock detection
#           via PID file (kill -0) prevents deadlock if a holder crashes.
#
# Acquire timeout: 10 s.
# ---------------------------------------------------------------------------

_state_have_flock() {
  command -v flock >/dev/null 2>&1
}

# _state_lock_acquire [artifact_dir]
#   Dispatches to flock or mkdir-mutex implementation.
#   Sets _STATE_LOCK_KIND ("flock" | "mkdir") so _state_lock_release picks
#   the correct release path.
_state_lock_acquire() {
  local artifact_dir="${1:-.}"
  if _state_have_flock; then
    _state_lock_acquire_flock "$artifact_dir"
  else
    _state_lock_acquire_mkdir "$artifact_dir"
  fi
}

# _state_lock_release [artifact_dir]
_state_lock_release() {
  local artifact_dir="${1:-.}"
  case "${_STATE_LOCK_KIND:-}" in
    flock) _state_lock_release_flock ;;
    mkdir) _state_lock_release_mkdir "$artifact_dir" ;;
    *) : ;;  # No lock held (or unknown kind); release is a no-op
  esac
  _STATE_LOCK_KIND=""
}

# ---- flock implementation (primary) ----
#
# Symlink-clobber defense: pre-existing symlinks at the lock path are
# detected and removed (defense in depth). Open uses APPEND (`>>`) instead
# of TRUNCATE (`>`) so a racing symlink replacement cannot clobber an
# attacker-chosen target. flock(1) operates on the FD inode, so append vs
# truncate is irrelevant for locking semantics.
_state_lock_acquire_flock() {
  local artifact_dir="${1:-.}"
  local lock_file="$artifact_dir/.qrspi/state.json.lock"

  if [[ -L "$lock_file" ]]; then
    if ! rm -f "$lock_file" 2>/dev/null; then
      echo "state_lock: refused to use $lock_file — pre-existing symlink that cannot be removed" >&2
      return 1
    fi
  fi

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
  local artifact_dir="${1:-.}"
  local lock_dir="$artifact_dir/.qrspi/state.json.lock"
  local pid_file="$lock_dir/owner.pid"
  local acquire_timeout=10

  local start
  start=$(date +%s)

  while true; do
    if mkdir "$lock_dir" 2>/dev/null; then
      # Acquired. Write owner.pid; FAIL CLOSED on metadata write error
      # (without owner.pid we cannot tell stale from live holders).
      if ! echo "$$" > "$pid_file" 2>/dev/null; then
        echo "state_lock: failed to write owner.pid in $lock_dir — aborting acquire" >&2
        rm -rf "$lock_dir" 2>/dev/null || true
        return 1
      fi
      _STATE_LOCK_KIND="mkdir"
      return 0
    fi

    # mkdir failed. Distinguish "lock already held" from "cannot create".
    if [[ ! -d "$lock_dir" ]]; then
      echo "state_lock: failed to create lock directory $lock_dir (permission denied or IO error)" >&2
      return 1
    fi

    # Lock held — check for stale owner via PID liveness only.
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
      rm -rf "$lock_dir" 2>/dev/null || true
      continue
    fi

    if (( now - start > acquire_timeout )); then
      local owner_str="$owner"
      [[ -z "$owner_str" ]] && owner_str="<owner.pid unreadable>"
      echo "state_lock: failed to acquire lock $lock_dir within ${acquire_timeout}s (held by PID $owner_str)" >&2
      return 1
    fi
    sleep 0.05 2>/dev/null || sleep 1
  done
}

_state_lock_release_mkdir() {
  local artifact_dir="${1:-.}"
  local lock_dir="$artifact_dir/.qrspi/state.json.lock"
  rm -rf "$lock_dir" 2>/dev/null || true
}

# state_compute_current_step <artifact_dir>
# Helper: scan artifact files in <artifact_dir>, determine the first pipeline step
# whose artifact frontmatter is not "approved", and echo that step name.
# Only the 8 file-backed steps (goals, questions, research, design, phasing,
# structure, plan, parallelize) are inspected. If all 8 are approved, echoes
# "implement" (the first non-file-backed step, defaults to "draft").
# Returns 1 if artifact_dir does not exist.
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

  echo "implement"
}

# state_init_or_reconcile <artifact_dir>
# Scans artifact files in the given directory, reads their frontmatter status,
# and creates/updates <artifact_dir>/.qrspi/state.json.
#
# Preserves an existing non-null phase_start_commit rather than wiping it on
# every call. Plan's narrow-direct-write must survive subsequent reconciliation.
state_init_or_reconcile() {
  local artifact_dir="$1"

  [[ -d "$artifact_dir" ]] || return 1

  # Determine statuses for all 10 artifacts (phasing sits between design and structure;
  # parallelize sits between plan and implement)
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

  # Determine current_step via single-source-of-truth helper.
  local current_step
  if ! current_step=$(state_compute_current_step "$artifact_dir"); then
    echo "state_init_or_reconcile: state_compute_current_step failed" >&2
    return 1
  fi

  # Defense-in-depth — validate delegated helper return value.
  if ! _state_current_step_is_allowed "$current_step"; then
    echo "state_init_or_reconcile: state_compute_current_step returned out-of-allowlist value '$current_step'" >&2
    return 1
  fi

  # Absolute path so artifact_dir can be cwd-independent
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$artifact_dir" && pwd)"

  local qrspi_dir="$abs_artifact_dir/.qrspi"
  if ! mkdir -p "$qrspi_dir" 2>/dev/null; then
    echo "state_init_or_reconcile: failed to create $qrspi_dir directory" >&2
    return 1
  fi

  # phase_start_commit read AND the rebuild+write MUST happen under the
  # same lock as state_update, otherwise a state_update writer can commit
  # a newer phase_start_commit between our read and our write.
  if ! _state_lock_acquire "$abs_artifact_dir"; then
    echo "state_init_or_reconcile: failed to acquire state lock" >&2
    return 1
  fi

  # Read existing phase_start_commit under lock.
  # Fail CLOSED on corrupt state.json (silent-failure round-2 finding 2).
  local phase_start_commit_arg=""
  local state_file="$qrspi_dir/state.json"
  if [[ -f "$state_file" ]]; then
    local existing_state
    if ! existing_state=$(cat "$state_file" 2>/dev/null); then
      echo "state_init_or_reconcile: failed to read existing $state_file under lock" >&2
      _state_lock_release "$abs_artifact_dir"
      return 1
    fi
    if [[ -n "$existing_state" ]]; then
      local existing_psc
      if ! existing_psc=$(echo "$existing_state" | jq -r '.phase_start_commit // ""' 2>/dev/null); then
        echo "state_init_or_reconcile: existing $state_file is corrupt (jq parse failed) — refusing to overwrite" >&2
        _state_lock_release "$abs_artifact_dir"
        return 1
      fi
      if [[ -n "$existing_psc" && "$existing_psc" != "null" ]]; then
        phase_start_commit_arg="$existing_psc"
      fi
    fi
  fi

  # Build state JSON. phase_start_commit is conditionally preserved (empty
  # sentinel → null).
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
    _state_lock_release "$abs_artifact_dir"
    return 1
  fi

  if [[ -z "$json" ]]; then
    echo "state_init_or_reconcile: jq failed — empty output" >&2
    _state_lock_release "$abs_artifact_dir"
    return 1
  fi

  local trimmed
  trimmed="${json#"${json%%[![:space:]]*}"}"
  if [[ "${trimmed:0:1}" != "{" ]] || [[ "${trimmed: -1}" != "}" ]]; then
    echo "state_init_or_reconcile: jq produced invalid JSON" >&2
    _state_lock_release "$abs_artifact_dir"
    return 1
  fi
  if [[ "$json" != *'"version"'* ]]; then
    echo "state_init_or_reconcile: jq produced JSON missing required fields" >&2
    _state_lock_release "$abs_artifact_dir"
    return 1
  fi

  # Inline write under the existing lock (bypass state_write_atomic to avoid
  # double-acquire). _state_write_inline_locked validates current_step and
  # does the temp-file + atomic mv.
  if ! _state_write_inline_locked "$json" "$abs_artifact_dir"; then
    echo "state_init_or_reconcile: locked write failed" >&2
    _state_lock_release "$abs_artifact_dir"
    return 1
  fi

  _state_lock_release "$abs_artifact_dir"
  return 0
}

# state_update <jq_filter> [--arg KEY VALUE | --argjson KEY VALUE]... [--artifact-dir DIR]
#
# Atomic read-modify-write of <artifact_dir>/.qrspi/state.json under the lock
# that state_write_atomic uses. Reads current state, applies <jq_filter>,
# validates the resulting current_step against the allowlist, and writes the
# result. The entire critical section is serialized.
#
# Filter parameters: callers SHOULD bind untrusted values via `--arg KEY VALUE`
# (string) or `--argjson KEY VALUE` (already-JSON value). The variadic args
# after the filter are forwarded verbatim to jq.
#
# Optional --artifact-dir DIR consumes 2 tokens; defaults to "." (PWD legacy).
state_update() {
  local filter="$1"
  shift

  local artifact_dir="."
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
      --artifact-dir)
        if [[ $# -lt 2 ]]; then
          echo "state_update: --artifact-dir requires DIR argument" >&2
          return 1
        fi
        artifact_dir="$2"
        shift 2
        ;;
      *)
        echo "state_update: unknown argument '$1' (only --arg / --argjson / --artifact-dir supported)" >&2
        return 1
        ;;
    esac
  done

  local qrspi_dir="$artifact_dir/.qrspi"
  if ! mkdir -p "$qrspi_dir" 2>/dev/null; then
    echo "state_update: failed to create $qrspi_dir directory" >&2
    return 1
  fi
  if ! _state_lock_acquire "$artifact_dir"; then
    return 1
  fi

  local state_file="$qrspi_dir/state.json"
  local current=""
  if [[ -f "$state_file" ]]; then
    if ! current=$(cat "$state_file" 2>/dev/null); then
      echo "state_update: failed to read $state_file under lock" >&2
      _state_lock_release "$artifact_dir"
      return 1
    fi
  else
    echo "state_update: $state_file does not exist (nothing to update)" >&2
    _state_lock_release "$artifact_dir"
    return 1
  fi

  # Apply filter via jq, forwarding any --arg / --argjson bindings.
  # The `${jq_args[@]+"${jq_args[@]}"}` form is a bash 3.2 + set -u workaround
  # for empty-array expansion.
  local updated
  if ! updated=$(echo "$current" | jq -c ${jq_args[@]+"${jq_args[@]}"} "$filter" 2>/dev/null); then
    echo "state_update: jq filter '$filter' failed" >&2
    _state_lock_release "$artifact_dir"
    return 1
  fi

  if ! _state_write_inline_locked "$updated" "$artifact_dir"; then
    echo "state_update: locked write failed" >&2
    _state_lock_release "$artifact_dir"
    return 1
  fi

  _state_lock_release "$artifact_dir"
  return 0
}

# _state_write_inline_locked <json> <artifact_dir>
# Internal helper. Caller MUST already hold the state lock for <artifact_dir>.
# Validates that <json> is an object containing "version", validates current_step
# (when present) against the allowlist via jq parsing (no raw substring), then
# writes via temp file + atomic mv into <artifact_dir>/.qrspi/state.json.
_state_write_inline_locked() {
  local json="$1"
  local artifact_dir="${2:-.}"
  local qrspi_dir="$artifact_dir/.qrspi"

  # Structural validation (round-3 silent-failure finding 1): payload must
  # be a JSON object containing "version".
  if ! echo "$json" | jq -e 'type == "object" and has("version")' >/dev/null 2>&1; then
    echo "state_lock: payload is not a JSON object with a 'version' field (refusing to write)" >&2
    return 1
  fi

  # Allowlist validation via jq (defeats unicode-escape bypass — round-2
  # silent-failure finding 1, security-reviewer finding 2).
  local cs
  if ! cs=$(echo "$json" | jq -r '.current_step // empty' 2>/dev/null); then
    echo "state_lock: payload not parseable as JSON (refusing to write)" >&2
    return 1
  fi
  if [[ -n "$cs" ]] && ! _state_current_step_is_allowed "$cs"; then
    echo "state_lock: current_step '$cs' is not in the allowlist (refusing to write)" >&2
    return 1
  fi

  # Atomic write: temp file in <qrspi_dir>/ + mv into place.
  local temp_file
  if ! temp_file=$(mktemp "$qrspi_dir/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_lock: failed to create temp file in $qrspi_dir/" >&2
    return 1
  fi
  if ! echo "$json" > "$temp_file" 2>/dev/null; then
    echo "state_lock: failed to write to temp file $temp_file" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi
  if ! mv "$temp_file" "$qrspi_dir/state.json" 2>/dev/null; then
    echo "state_lock: failed to move temp file to $qrspi_dir/state.json" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi
  return 0
}

# state_read [artifact_dir]
# Outputs <artifact_dir>/.qrspi/state.json on stdout, returns 0.
# If artifact_dir is omitted, reads from .qrspi/state.json relative to PWD
# (legacy behavior — preserved for callers that pre-cd into the artifact_dir).
# Returns 1 if file doesn't exist.
state_read() {
  local artifact_dir="${1:-.}"
  local state_file="$artifact_dir/.qrspi/state.json"

  if [[ -f "$state_file" ]]; then
    cat "$state_file"
    return 0
  else
    return 1
  fi
}

# state_write_atomic <json_string> [artifact_dir]
# Writes JSON to <artifact_dir>/.qrspi/state.json via temp file + mv for atomicity.
# Creates <artifact_dir>/.qrspi/ directory if needed.
# If artifact_dir is omitted, writes to .qrspi/state.json relative to PWD
# (legacy behavior — preserved for callers that pre-cd into the artifact_dir).
#
# Hardening:
#   - Allowlist: validates current_step against the 12-value enum (when present).
#   - TOCTOU: serializes via portable file lock (flock or mkdir-mutex) at
#     <artifact_dir>/.qrspi/state.json.lock.
#
# state_write_atomic protects single writes against torn writes (atomic mv).
# Callers doing read-modify-write across separate state_read + state_write_atomic
# calls have an open R-M-W window and MUST use state_update instead.
state_write_atomic() {
  local json="$1"
  local artifact_dir="${2:-.}"
  local qrspi_dir="$artifact_dir/.qrspi"

  if ! mkdir -p "$qrspi_dir" 2>/dev/null; then
    echo "state_write_atomic: failed to create $qrspi_dir directory" >&2
    return 1
  fi

  if ! _state_lock_acquire "$artifact_dir"; then
    return 1
  fi

  if ! _state_write_inline_locked "$json" "$artifact_dir"; then
    _state_lock_release "$artifact_dir"
    return 1
  fi

  _state_lock_release "$artifact_dir"
  return 0
}
