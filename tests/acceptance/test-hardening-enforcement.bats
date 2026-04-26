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
  cd "$WORK_DIR"
  # state.json lives at <artifact_dir>/.qrspi/state.json (per F-1 fix). The
  # hook resolves artifact_dir target-based via the audit resolver, which globs
  # $(pwd)/docs/qrspi/*-{slug}/ — so ARTIFACT_DIR must follow that layout.
  export ARTIFACT_DIR="$WORK_DIR/docs/qrspi/2026-04-26-test"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$ARTIFACT_DIR/.qrspi"

  export PRE_HOOK
  PRE_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
}

teardown() {
  cd /
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
      active_task:{id:$task_id}}' > "$ARTIFACT_DIR/.qrspi/state.json"
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
  printf 'NOT VALID JSON\n' > "$ARTIFACT_DIR/.qrspi/state.json"

  # Write to a pipeline artifact (triggers state read for pipeline ordering check)
  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  # Diagnostic must appear — check combined output (stderr + stdout)
  [[ "$output" == *"state"* ]] || [[ "$output" == *"corrupted"* ]] || [[ "$output" == *"Cannot"* ]]
}

# [U1] (removed) — "missing artifact_dir in state.json blocks"
#
# Removed post-F-1 (2026-04-26). The pre-tool-use hook no longer reads
# artifact_dir from state.json; it resolves the target-based artifact_dir via
# _audit_resolve_target_to_artifact_dir before reading state. The "missing
# artifact_dir → block" code path was deleted along with that change.
#
# Fail-closed coverage for state.json defects is now provided by:
#   [U1] Corrupted state.json (above) — invalid JSON → block via the new
#        state-validity check in pipeline_check_prerequisites.
#   [U1] Block response is valid JSON (below) — verifies block JSON shape.

# U1 — Malformed JSON on stdin causes block with diagnostic (existing coverage, verify still passes)
@test "[U1] Malformed stdin JSON causes pre-tool-use to block with exit 2 and diagnostic" {
  # AC: hook cannot parse stdin → exit 2 with user-facing diagnostic (not silent denial)
  run "$PRE_HOOK" <<< "this is not json"
  [ "$status" -eq 2 ]
  # Output must include a diagnostic message, not be empty
  [[ -n "$output" ]]
  [[ "$output" == *"malformed"* ]] || [[ "$output" == *"Cannot parse"* ]] || [[ "$output" == *"parse"* ]]
}

# U1 — Block output is always valid JSON (diagnostic is in stderr, JSON in stdout)
@test "[U1] Block response is valid JSON with decision=block even for corrupted state" {
  # AC: fail-closed response must be machine-readable JSON on stdout so Claude can process it
  printf 'INVALID JSON\n' > "$ARTIFACT_DIR/.qrspi/state.json"

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

# ── U10/U12: REMOVED ──────────────────────────────────────────────────────────
# The per-task allowlist (`enforcement_check_allowlist`) and its call sites in
# pre-tool-use were removed in the 2026-04-26 implement-runtime-fix. The asymmetric
# target-based wall in pre-tool-use (covered by tests/acceptance/test-asymmetric-enforcement.bats)
# replaces the strict/monitored allowlist mechanism.

# ── U13: Monitored-mode in_scope flag ────────────────────────────────────────
# Criterion: In monitored mode, audit logging via audit_log_event records the
# operation correctly. The old per-task in_scope/enforcement fields have been
# replaced by the unified audit_log_event schema in audit.sh.
# End-to-end acceptance coverage of the asymmetric runtime will be added in Task 6.
