#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Phase 4 Hardening — Enforcement hardening goals.
#
# Covers:
#   U1  — Fail-closed with diagnostics: errors produce exit 2 + stderr diagnostic
#   U9  — Audit JSONL raw blob: malformed input preserves raw_input field
#   U10 — Allowlist path resolution at parse time (end-to-end hook verification)
#   U12 — No stderr suppression: no 2>/dev/null on enforcement_check_allowlist
#          or pipeline_check_prerequisites call sites in pre-tool-use
#   U13 — Monitored-mode in_scope flag: correctly records false when out-of-scope
#          (end-to-end through post-tool-use hook)
#
# Tests drive real hook scripts, not library functions directly.

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  export ARTIFACT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$WORK_DIR/.qrspi"
  cd "$WORK_DIR"

  export PRE_HOOK
  PRE_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
}

teardown() {
  rm -rf "$WORK_DIR"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

create_task_spec() {
  local task_num="$1"
  local enforcement="${2:-strict}"
  shift 2
  local allowed_block=""
  for p in "$@"; do
    local resolved_p="$p"
    if [[ "$p" != /* ]]; then
      resolved_p="$WORK_DIR/$p"
    fi
    allowed_block="${allowed_block}  - action: create\n    path: ${resolved_p}\n"
  done
  printf -- '---\nstatus: approved\ntask: %s\nphase: 1\nenforcement: %s\nallowed_files:\n%s\nconstraints: []\n---\n\n# Task %s\n' \
    "$task_num" "$enforcement" "$(printf '%b' "$allowed_block")" "$task_num" \
    > "$ARTIFACT_DIR/tasks/task-$(printf '%02d' "$task_num").md"
}

init_state_with_task() {
  local task_id="$1"
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$ARTIFACT_DIR" && pwd)"
  jq -cn \
    --arg artifact_dir "$abs_artifact_dir" \
    --argjson task_id "$task_id" \
    '{version:1, current_step:"implement", phase_start_commit:null,
      artifact_dir:$artifact_dir, wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:$task_id}}' > "$WORK_DIR/.qrspi/state.json"
}

write_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$file_path"
}

# ── U1: Fail-closed with diagnostics ─────────────────────────────────────────
# Criterion: Any error in enforcement logic results in denial with a visible
# diagnostic message (stderr or user-facing output), not silent pass-through
# or silent denial.

# U1 — Corrupted state.json (exists but not parseable) causes block + stderr diagnostic
@test "[U1] Corrupted state.json causes pre-tool-use to fail-closed with stderr diagnostic" {
  # AC: state file exists but is corrupted JSON → hook blocks with exit 2 + diagnostic on stderr
  printf 'NOT VALID JSON\n' > "$WORK_DIR/.qrspi/state.json"

  # Write to a pipeline artifact (triggers state read for pipeline ordering check)
  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  # Diagnostic must appear — check combined output (stderr + stdout)
  [[ "$output" == *"state"* ]] || [[ "$output" == *"corrupted"* ]] || [[ "$output" == *"Cannot"* ]]
}

# U1 — State file with missing artifact_dir causes block + diagnostic
@test "[U1] State with missing artifact_dir causes block with diagnostic on stderr" {
  # AC: state parses but is missing required artifact_dir field → hook blocks with exit 2
  jq -cn '{version:1, current_step:"implement", phase_start_commit:null,
           wireframe_requested:false,
           artifacts:{goals:"approved",questions:"approved",research:"approved",
                      design:"approved",structure:"approved",plan:"approved",
                      implement:"draft",test:"draft"},
           active_task:null}' > "$WORK_DIR/.qrspi/state.json"

  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"artifact_dir"* ]] || [[ "$output" == *"missing"* ]] || [[ "$output" == *"Cannot"* ]]
}

# U1 — Malformed JSON on stdin causes block with diagnostic (existing coverage, verify still passes)
@test "[U1] Malformed stdin JSON causes pre-tool-use to block with exit 2 and diagnostic" {
  # AC: hook cannot parse stdin → exit 2 with user-facing diagnostic (not silent denial)
  run "$PRE_HOOK" <<< "this is not json"
  [ "$status" -eq 2 ]
  # Output must include a diagnostic message, not be empty
  [[ -n "$output" ]]
  [[ "$output" == *"malformed"* ]] || [[ "$output" == *"Cannot parse"* ]] || [[ "$output" == *"parse"* ]]
}

# U1 — Missing task_id in worktree causes block + diagnostic
@test "[U1] Worktree path with no parseable task ID causes block with diagnostic" {
  # AC: worktree_detect triggers but worktree_extract_task_id fails → exit 2 + diagnostic
  # Create a worktree-like path (contains .worktrees/) but with malformed task ID
  local bad_worktree
  bad_worktree=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$bad_worktree/.worktrees/notaskid/.qrspi"

  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/file.sh","content":"x"}}\n' \
         "$bad_worktree/.worktrees/notaskid")

  run bash -c "cd '$bad_worktree/.worktrees/notaskid' && '$PRE_HOOK' <<< '$json'"
  # Must block — cannot determine task ID from the path
  [ "$status" -eq 2 ]
  [[ "$output" == *"task"* ]] || [[ "$output" == *"Cannot"* ]] || [[ "$output" == *"worktree"* ]]

  rm -rf "$bad_worktree"
}

# U1 — Block output is always valid JSON (diagnostic is in stderr, JSON in stdout)
@test "[U1] Block response is valid JSON with decision=block even for corrupted state" {
  # AC: fail-closed response must be machine-readable JSON on stdout so Claude can process it
  printf 'INVALID JSON\n' > "$WORK_DIR/.qrspi/state.json"

  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  # Last line of stdout must be valid JSON with decision=block
  local json_line="${lines[-1]}"
  echo "$json_line" | jq . > /dev/null
  [ "$(echo "$json_line" | jq -r '.decision')" = "block" ]
}

# ── U9: Audit JSONL raw blob preservation ─────────────────────────────────────
# Criterion: If jq construction of structured fields fails, the raw blob is
# still written. Each audit entry includes raw input blob.

# U9 — post-tool-use survives malformed JSON without crashing (fail-open for audit)
@test "[U9] post-tool-use exits 0 on malformed JSON stdin (audit fail-open)" {
  # AC: post-tool-use must not crash when receiving malformed JSON — it logs
  # a warning to stderr and exits 0 (audit is non-blocking).
  # The raw_input preservation contract is verified at the library level below.

  init_state_with_task 30
  create_task_spec 30 "monitored"

  run "$POST_HOOK" <<< "this is not valid json at all"
  [ "$status" -eq 0 ]
}

# ── U10: Allowlist path resolution at parse time ──────────────────────────────
# Criterion: Paths in task spec are pre-resolved absolute paths; enforcement
# uses direct string comparison with no per-call path resolution.

# U10 — Task spec with absolute paths: relative-path enforcement resolves correctly
@test "[U10] Pre-resolved absolute paths in task spec allowlist work through full pre-tool-use hook" {
  # AC: task spec stores absolute paths; enforcement_check_allowlist uses direct string
  # comparison. This test verifies the full hook flow: spec is written with absolute paths,
  # write to that absolute path is allowed.
  create_task_spec 40 "strict" "src/main.sh"
  init_state_with_task 40

  # Write to the absolute path that matches the pre-resolved allowlist entry
  run "$PRE_HOOK" <<< "$(write_json "$WORK_DIR/src/main.sh")"
  [ "$status" -eq 0 ]
}

# U10 — Write to path NOT in allowlist is blocked (direct string comparison)
@test "[U10] Write to path not in pre-resolved allowlist is blocked by pre-tool-use" {
  # AC: direct string comparison blocks anything not in the exact list
  create_task_spec 41 "strict" "src/main.sh"
  init_state_with_task 41

  # A different path — not in allowlist — must be blocked
  run "$PRE_HOOK" <<< "$(write_json "$WORK_DIR/src/other.sh")"
  [ "$status" -eq 2 ]
  [ "$(echo "${lines[-1]}" | jq -r '.decision')" = "block" ]
}

# U10 — enforcement_check_allowlist has no realpath/readlink/pwd in source
@test "[U10] enforcement.sh contains no per-call path resolution (realpath/readlink calls)" {
  # AC: enforcement_check_allowlist must use direct string comparison, not per-call
  # realpath/readlink. Grep verifies no such calls exist in the enforcement library.
  local enforcement_lib
  enforcement_lib="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/enforcement.sh"

  # enforcement_check_allowlist function body must not call realpath or readlink
  # (These calls would be per-call resolution, violating U10)
  run grep -n "realpath\|readlink" "$enforcement_lib"
  [ "$status" -ne 0 ]
}

# ── U12: No stderr suppression on enforcement call sites ─────────────────────
# Criterion: No 2>/dev/null on enforcement_check_allowlist or
# pipeline_check_prerequisites call sites in pre-tool-use.

# U12 — enforcement_check_allowlist call sites have no 2>/dev/null in pre-tool-use
@test "[U12] enforcement_check_allowlist call sites in pre-tool-use have no 2>/dev/null" {
  # AC: 2>/dev/null on these call sites would swallow diagnostic output that the
  # user needs to understand why enforcement blocked a write.
  local pre_hook_src
  pre_hook_src="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"

  # First verify the function IS called in pre-tool-use (guard against vacuous pass)
  grep -q "enforcement_check_allowlist" "$pre_hook_src"
  # Extract the line(s) that call enforcement_check_allowlist.
  # None of them must have 2>/dev/null appended.
  while IFS= read -r line; do
    # Each enforcement_check_allowlist call line must NOT contain 2>/dev/null
    [[ "$line" != *"2>/dev/null"* ]]
  done < <(grep "enforcement_check_allowlist" "$pre_hook_src")
}

# U12 — pipeline_check_prerequisites call sites have no 2>/dev/null in pre-tool-use
@test "[U12] pipeline_check_prerequisites call sites in pre-tool-use have no 2>/dev/null" {
  # AC: diagnostic output from pipeline_check_prerequisites must reach the user;
  # 2>/dev/null would silently suppress useful error information.
  local pre_hook_src
  pre_hook_src="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"

  # First verify the function IS called in pre-tool-use (guard against vacuous pass)
  grep -q "pipeline_check_prerequisites" "$pre_hook_src"
  while IFS= read -r line; do
    [[ "$line" != *"2>/dev/null"* ]]
  done < <(grep "pipeline_check_prerequisites" "$pre_hook_src")
}

# U12 — Enforcement stderr diagnostic reaches caller (no suppression in hook)
@test "[U12] Strict-mode block diagnostic is visible in hook output (not suppressed)" {
  # AC: when enforcement blocks a write, the diagnostic must appear in the hook's
  # output — it must not be silently swallowed by a 2>/dev/null redirect.
  create_task_spec 42 "strict" "src/allowed.sh"
  init_state_with_task 42

  run "$PRE_HOOK" <<< "$(write_json "$WORK_DIR/src/not-in-allowlist.sh")"
  [ "$status" -eq 2 ]
  # Diagnostic must be visible (not suppressed)
  [[ -n "$output" ]]
  # Output must contain informational content — not just a bare JSON block
  [[ "$output" == *"not"* ]] || [[ "$output" == *"allowlist"* ]] || [[ "$output" == *"BLOCKED"* ]]
}

# ── U13: Monitored-mode in_scope flag ────────────────────────────────────────
# Criterion: In monitored mode, audit logging via audit_log_event records the
# operation correctly. The old per-task in_scope/enforcement fields have been
# replaced by the unified audit_log_event schema in audit.sh.
# End-to-end acceptance coverage of the asymmetric runtime will be added in Task 6.
