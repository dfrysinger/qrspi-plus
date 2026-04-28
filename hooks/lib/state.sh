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
_state_lock_acquire_flock() {
  local lock_file=".qrspi/state.json.lock"
  # Touch the lock file so flock can open it.
  if ! : > "$lock_file" 2>/dev/null; then
    # If the lock file already exists with content (from a previous flock
    # run), that's fine — flock locks the file, not its contents. Only
    # complain if we cannot create or access it.
    if [[ ! -e "$lock_file" ]]; then
      echo "state_write_atomic: failed to create lock file $lock_file" >&2
      return 1
    fi
  fi
  # Open lock file on FD 9 in the current shell, then flock-exclusive
  # with 10s timeout.
  exec 9>"$lock_file" || {
    echo "state_write_atomic: failed to open lock file $lock_file on FD 9" >&2
    return 1
  }
  if ! flock -w 10 9 2>/dev/null; then
    echo "state_write_atomic: failed to acquire flock on $lock_file within 10s" >&2
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
  local started_file="$lock_dir/started.epoch"
  local stale_timeout=30
  local acquire_timeout=10

  local start
  start=$(date +%s)

  while true; do
    if mkdir "$lock_dir" 2>/dev/null; then
      # Acquired
      echo "$$" > "$pid_file" 2>/dev/null || true
      date +%s > "$started_file" 2>/dev/null || true
      _STATE_LOCK_KIND="mkdir"
      return 0
    fi

    # mkdir failed. Distinguish "lock already held" (lock_dir exists)
    # from "cannot create" (permissions, parent missing, IO error). In the
    # latter case retrying is futile — fail fast so callers get a clean
    # error rather than spinning to the acquire-timeout deadline.
    if [[ ! -d "$lock_dir" ]]; then
      echo "state_write_atomic: failed to create lock directory $lock_dir (permission denied or IO error)" >&2
      return 1
    fi

    # Lock held — check for stale owner
    local owner=""
    [[ -f "$pid_file" ]] && owner=$(cat "$pid_file" 2>/dev/null || echo "")
    local started=0
    [[ -f "$started_file" ]] && started=$(cat "$started_file" 2>/dev/null || echo 0)
    local now
    now=$(date +%s)

    local stale=false
    if [[ -n "$owner" ]] && ! kill -0 "$owner" 2>/dev/null; then
      stale=true
    fi
    if (( now - started > stale_timeout )); then
      stale=true
    fi

    if $stale; then
      # Reclaim: remove lock dir and retry. Use rm -rf since the dir has
      # contents (pid_file, started_file).
      rm -rf "$lock_dir" 2>/dev/null || true
      continue
    fi

    # Bounded wait
    if (( now - start > acquire_timeout )); then
      echo "state_write_atomic: failed to acquire lock $lock_dir within ${acquire_timeout}s (held by PID $owner)" >&2
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
# Only the 7 file-backed steps (goals, questions, research, design, phasing,
# structure, plan) are inspected. If all 7 are approved, echoes "implement"
# (the first non-file-backed step, which defaults to "draft"). This matches
# state_init_or_reconcile, where implement is the next step in pipeline order
# after plan-approved.
# Returns 1 if artifact_dir does not exist.
#
# Single source of truth for the "first non-approved step" computation.
# state_init_or_reconcile delegates here (FU-1 refactor 2026-04-28).
state_compute_current_step() {
  local artifact_dir="$1"
  [[ -d "$artifact_dir" ]] || return 1

  local _step _artifact_file _status
  for _step in goals questions research design phasing structure plan; do
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
  # all 7 file-backed steps are approved (matches state_init_or_reconcile: the
  # next step after plan-approved is implement, since implement is also "draft"
  # by default and is the first non-approved step in pipeline order).
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

  # Determine statuses for all 9 artifacts (M54 added phasing between design and structure)
  local goals_status="draft"
  local questions_status="draft"
  local research_status="draft"
  local design_status="draft"
  local phasing_status="draft"
  local structure_status="draft"
  local plan_status="draft"
  local implement_status="draft"
  local test_status="draft"

  # Check each artifact file using canonical mapping
  local _step _artifact_file
  for _step in goals questions research design phasing structure plan; do
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

  # T24-B: preserve phase_start_commit from existing state.json (R2 I-N3).
  # If state.json exists and has a non-null phase_start_commit, carry it
  # forward; otherwise initialize null (existing behavior).
  local phase_start_commit_arg=""
  local existing_psc=""
  if [[ -f ".qrspi/state.json" ]]; then
    existing_psc=$(jq -r '.phase_start_commit // ""' ".qrspi/state.json" 2>/dev/null || echo "")
    if [[ -n "$existing_psc" && "$existing_psc" != "null" ]]; then
      phase_start_commit_arg="$existing_psc"
    fi
  fi

  # Create absolute path for artifact_dir
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$artifact_dir" && pwd)"

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
        implement: $implement,
        test: $test
      }
    }'); then
    echo "state_init_or_reconcile: jq failed to build state JSON" >&2
    return 1
  fi

  if [[ -z "$json" ]]; then
    echo "state_init_or_reconcile: jq failed — empty output" >&2
    return 1
  fi

  # Validate output is well-formed JSON before writing (basic structural check)
  # Check starts with { and ends with }, and contains required "version" key
  local trimmed
  trimmed="${json#"${json%%[![:space:]]*}"}"
  if [[ "${trimmed:0:1}" != "{" ]] || [[ "${trimmed: -1}" != "}" ]]; then
    echo "state_init_or_reconcile: jq produced invalid JSON" >&2
    return 1
  fi
  if [[ "$json" != *'"version"'* ]]; then
    echo "state_init_or_reconcile: jq produced JSON missing required fields" >&2
    return 1
  fi

  # Write the state file atomically (state_write_atomic also enforces
  # current_step allowlist + lock-serializes the critical section).
  if ! state_write_atomic "$json"; then
    echo "state_init_or_reconcile: state_write_atomic failed" >&2
    return 1
  fi
}

# state_update <jq_filter>
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
# Example: state_update '.phase_start_commit = "abc123"'
#
# Returns:
#   0 on success
#   1 on lock acquire failure, jq error, or write error (with stderr diagnostic)
state_update() {
  local filter="$1"

  # Acquire lock for the entire R-M-W critical section.
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

  # Apply filter via jq.
  local updated
  if ! updated=$(echo "$current" | jq -c "$filter" 2>/dev/null); then
    echo "state_update: jq filter '$filter' failed" >&2
    _state_lock_release
    return 1
  fi

  # Validate current_step in the result against the allowlist.
  if [[ "$updated" == *'"current_step"'* ]]; then
    local cs
    cs=$(echo "$updated" | jq -r '.current_step // empty' 2>/dev/null || echo "")
    if [[ -n "$cs" ]] && ! _state_current_step_is_allowed "$cs"; then
      echo "state_update: filter produced out-of-allowlist current_step '$cs' (refusing to write)" >&2
      _state_lock_release
      return 1
    fi
  fi

  # Write atomically. We bypass state_write_atomic's internal lock to
  # avoid double-acquire — instead we inline the temp-file + mv write
  # under the existing lock.
  local temp_file
  if ! temp_file=$(mktemp ".qrspi/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_update: failed to create temp file" >&2
    _state_lock_release
    return 1
  fi
  if ! echo "$updated" > "$temp_file" 2>/dev/null; then
    echo "state_update: failed to write temp file" >&2
    rm -f "$temp_file" 2>/dev/null
    _state_lock_release
    return 1
  fi
  if ! mv "$temp_file" ".qrspi/state.json" 2>/dev/null; then
    echo "state_update: failed to mv temp file into place" >&2
    rm -f "$temp_file" 2>/dev/null
    _state_lock_release
    return 1
  fi

  _state_lock_release
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
#     rejected fail-closed (non-zero exit, no write).
#   - R2 S-N4 TOCTOU: serializes the critical section via a portable mkdir-
#     based file lock in .qrspi/state.json.lock. The lock is acquired BEFORE
#     mkdir/.qrspi/, written under lock, and released on every exit path
#     (including validation failures and signals via trap).
state_write_atomic() {
  local json="$1"

  # T24-A allowlist: validate current_step BEFORE acquiring lock or
  # touching disk. Reject out-of-allowlist values fail-closed.
  if [[ "$json" == *'"current_step"'* ]]; then
    # Extract current_step value via jq; tolerate missing field by checking
    # for non-null/non-empty before validating.
    local cs
    if ! cs=$(echo "$json" | jq -r '.current_step // empty' 2>/dev/null); then
      echo "state_write_atomic: payload not parseable as JSON" >&2
      return 1
    fi
    if [[ -n "$cs" ]] && ! _state_current_step_is_allowed "$cs"; then
      echo "state_write_atomic: current_step '$cs' is not in the allowlist (refusing to write)" >&2
      return 1
    fi
  fi

  # Create .qrspi directory if needed (must exist before lock dir creation)
  if ! mkdir -p ".qrspi" 2>/dev/null; then
    echo "state_write_atomic: failed to create .qrspi directory" >&2
    return 1
  fi

  # T24-C: acquire lock for the read-modify-write critical section.
  # We use explicit release at every return path. RETURN traps interact
  # poorly with `set -u` and bats' `run` wrapper, so a flag + trap was
  # ruled out in favor of straight-line release calls.
  if ! _state_lock_acquire; then
    return 1
  fi

  # ---- critical section: any return below MUST release the lock ----

  # Create temp file in the same directory to ensure atomic rename
  local temp_file
  if ! temp_file=$(mktemp ".qrspi/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_write_atomic: failed to create temp file in .qrspi/" >&2
    _state_lock_release
    return 1
  fi

  # Write JSON to temp file
  if ! echo "$json" > "$temp_file" 2>/dev/null; then
    echo "state_write_atomic: failed to write to temp file $temp_file" >&2
    rm -f "$temp_file" 2>/dev/null
    _state_lock_release
    return 1
  fi

  # Atomically move temp file to final location
  if ! mv "$temp_file" ".qrspi/state.json" 2>/dev/null; then
    echo "state_write_atomic: failed to move temp file to .qrspi/state.json" >&2
    rm -f "$temp_file" 2>/dev/null
    _state_lock_release
    return 1
  fi

  _state_lock_release
  return 0
}
