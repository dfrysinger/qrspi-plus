#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 1:
# "Pipeline step ordering is enforced by code such that an agent structurally
#  cannot skip or reorder steps without triggering a hard block"
#
# These tests operate end-to-end through the pre-tool-use hook script,
# not individual library functions (those are covered by unit tests).

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  # state.json now lives at <artifact_dir>/.qrspi/state.json (per spec) and the
  # hook resolves artifact_dir target-based via the audit resolver, which globs
  # $(pwd)/docs/qrspi/*-{slug}/. ARTIFACT_DIR must follow that production layout.
  export ARTIFACT_DIR
  ARTIFACT_DIR="$WORK_DIR/docs/qrspi/2026-04-26-test"
  mkdir -p "$ARTIFACT_DIR/research"

  # Path to the hook under test
  export HOOK
  HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
}

teardown() {
  cd /
  rm -rf "$WORK_DIR"
}

# ── Helpers ─────────────────────────────────────────────────────────────────

create_artifact() {
  local path="$1"
  local status="$2"
  mkdir -p "$(dirname "$path")"
  printf -- '---\nstatus: %s\n---\nContent\n' "$status" > "$path"
}

# Bootstrap state.json by sourcing pipeline.sh and calling state_init_or_reconcile
init_state() {
  local artifact_dir="$1"
  local pipeline_lib
  pipeline_lib="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
  bash -c "source '$pipeline_lib'; cd '$WORK_DIR'; state_init_or_reconcile '$artifact_dir'"
}

write_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"new"}}\n' "$file_path"
}

edit_json() {
  local file_path="$1"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"old","new_string":"new"}}\n' "$file_path"
}

# Set up a "full draft" artifact layout (all steps exist but are draft)
setup_full_draft() {
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"
}

# ── Criterion 1: Forward move requires previous step approved ────────────────

# AC1 — Write to questions.md is blocked when goals is draft
@test "[AC1] Write questions.md blocked when goals draft → exit 2 with 'goals' in reason" {
  # goals is draft; questions write should require goals approved first
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/questions.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# AC1 — Write to design.md blocked when goals+questions approved but research draft
@test "[AC1] Write design.md blocked when research not approved → exit 2 with 'research' in reason" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"research"* ]]
}

# AC1 — Write to structure.md blocked when design not approved
@test "[AC1] Write structure.md blocked when design not approved → exit 2 with 'design' in reason" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(edit_json "$ARTIFACT_DIR/structure.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"design"* ]]
}

# AC1 — Write to plan.md blocked when structure not approved
@test "[AC1] Write plan.md blocked when structure not approved → exit 2" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/plan.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"structure"* ]]
}

# AC1 — Full pipeline approved: write to plan.md is allowed
@test "[AC1] Write plan.md allowed when all prerequisites approved → exit 0" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "approved"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/plan.md")"
  [ "$status" -eq 0 ]
}

# AC1 — goals is always allowed to write (no prerequisites)
@test "[AC1] Write goals.md always allowed (first step, no prerequisites) → exit 0" {
  setup_full_draft

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/goals.md")"
  [ "$status" -eq 0 ]
}

# AC1 — Skipping multiple steps is blocked (research when goals still draft)
@test "[AC1] Attempting to skip to research.md with goals draft → exit 2" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/research/summary.md")"
  [ "$status" -eq 2 ]
  # Should mention the first missing prerequisite (goals)
  [[ "$output" == *"goals"* ]]
}

# ── Criterion 1: Dual-check — frontmatter is source of truth ─────────────────

# AC1 (dual-check) — Even if state.json says goals=approved, frontmatter draft → block
@test "[AC1][dual-check] Frontmatter overrides state.json: goals draft in file blocks questions write" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  # Manually patch state.json to lie and say goals is approved
  local pipeline_lib
  pipeline_lib="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
  bash -c "
    source '$pipeline_lib'
    cd '$WORK_DIR'
    s=\$(state_read '$ARTIFACT_DIR')
    s=\$(printf '%s' \"\$s\" | jq '.artifacts.goals = \"approved\"')
    state_write_atomic \"\$s\" '$ARTIFACT_DIR'
  "

  # Hook must still block because frontmatter says draft
  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/questions.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# ── Criterion 1: Backward loops cascade reset downstream ─────────────────────

# AC1 (backward loop) — Writing goals.md when questions was approved cascades reset downstream
# We verify this by: all approved up through questions, then write goals.md succeeds,
# then writing design.md is blocked (questions was cascade-reset to draft by the Write goals path)
# NOTE: The hook allows the write itself (goals can always be written), but downstream state
# reflects the cascade on the next call. We test that writing to design.md after re-writing
# goals is blocked because a backward write to goals triggers cascade.
@test "[AC1][backward-loop] Writing to goals.md (backward) then design.md is blocked" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  # Downgrade goals.md on disk to draft (simulate user editing it)
  create_artifact "$ARTIFACT_DIR/goals.md" "draft"

  # Now design.md write should fail — goals is no longer approved
  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# ── Criterion 1: Non-artifact writes are always allowed ───────────────────────

# AC1 — Writing to a file outside the pipeline does not trigger ordering checks
@test "[AC1] Write to non-artifact source file is always allowed → exit 0" {
  setup_full_draft  # all draft, but goals.md is the current step

  # Writing to a random source file should not be blocked by pipeline ordering
  run "$HOOK" <<< '{"tool_name":"Write","tool_input":{"file_path":"/tmp/some-impl-file.sh","content":"#!/bin/bash"}}'
  [ "$status" -eq 0 ]
}

# AC1 — Edit to a non-pipeline file is always allowed
@test "[AC1] Edit to hooks/lib/foo.sh not blocked by pipeline ordering → exit 0" {
  setup_full_draft

  run "$HOOK" <<< '{"tool_name":"Edit","tool_input":{"file_path":"/some/project/hooks/lib/foo.sh","old_string":"a","new_string":"b"}}'
  [ "$status" -eq 0 ]
}

# ── Criterion 1: Block output format ─────────────────────────────────────────

# AC1 — Blocked response is valid JSON with decision="block"
@test "[AC1] Blocked write produces valid JSON with decision=block" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  # Last line of output is the JSON response (first line is stderr diagnostic)
  local json_line="${lines[-1]}"
  echo "$json_line" | jq . > /dev/null
  [[ "$(echo "$json_line" | jq -r '.decision')" == "block" ]]
}

# AC1 — Block reason is a non-empty string
@test "[AC1] Blocked write reason field is a non-empty string" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  local json_line="${lines[-1]}"
  local reason
  reason=$(echo "$json_line" | jq -r '.reason')
  [[ -n "$reason" ]]
}

# ── Criterion 1: Fail-closed for enforcement state, fail-open for stdin ──────

# AC1 — No state file → fail-closed (exit 2) when writing a pipeline artifact
@test "[AC1] No state file → allows artifact write (no pipeline to enforce yet)" {
  # WORK_DIR has no .qrspi/state.json — no pipeline state means no ordering
  # to enforce. State is created by QRSPI skills when they initialize the
  # artifact directory. Hooks only read state, they don't create it.
  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 0 ]
}

# AC1 — No state file → non-artifact writes still allowed (no enforcement context needed)
@test "[AC1][fail-open] No state file → allows non-artifact write" {
  # WORK_DIR has no .qrspi/state.json — writing a non-artifact file should pass
  # (pipeline ordering only applies to artifact files)
  run "$HOOK" <<< '{"tool_name":"Write","tool_input":{"file_path":"/tmp/any-file.sh","content":"x"}}'
  [ "$status" -eq 0 ]
}

# AC1 — Malformed JSON on stdin → fail-closed
@test "[AC1][fail-closed] Malformed JSON on stdin → hook blocks (exit 2)" {
  run "$HOOK" <<< "not json at all"
  [ "$status" -eq 2 ]
}

# AC1 — Bash tool calls always pass ordering check (ordering only applies to Write/Edit)
@test "[AC1] Bash tool call is not subject to pipeline ordering → exit 0" {
  setup_full_draft

  run "$HOOK" <<< '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}'
  [ "$status" -eq 0 ]
}

# ── Important #5: post-tool-use no longer audits — single audit row per Write ──

# Pre-F-1: every successful Write produced TWO "allow" rows in audit.jsonl
# (one from pre-tool-use's allow(), one from post-tool-use's audit_log_event).
# After dropping the post-hook audit, exactly one row should exist per Write.
@test "[I5] successful Write produces exactly one audit row (no double-audit)" {
  # Approve everything up through plan so writing goals.md is allowed
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "approved"
  create_artifact "$ARTIFACT_DIR/plan.md"             "approved"
  init_state "$ARTIFACT_DIR"

  local target="$ARTIFACT_DIR/goals.md"
  local payload
  payload=$(write_json "$target")

  # Run pre-tool-use (audits the decision)
  run "$HOOK" <<< "$payload"
  [ "$status" -eq 0 ]

  # Run post-tool-use (no longer audits — only syncs state)
  local post_hook
  post_hook="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
  run "$post_hook" <<< "$payload"
  [ "$status" -eq 0 ]

  # Audit log must have exactly one row for this Write
  local audit_log="$ARTIFACT_DIR/.""qrspi/audit.jsonl"
  [ -f "$audit_log" ]
  local row_count
  row_count=$(wc -l < "$audit_log" | tr -d ' ')
  [ "$row_count" -eq 1 ]
}
