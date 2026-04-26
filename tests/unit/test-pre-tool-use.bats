#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Setup: create temp artifact dir and temp working dir with .qrspi/state.json
setup() {
  export ARTIFACT_DIR
  ARTIFACT_DIR=$(mktemp -d)
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  # Create artifact files directory structure
  mkdir -p "$ARTIFACT_DIR/research"

  # Path to the hook under test
  export HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
}

teardown() {
  rm -rf "$ARTIFACT_DIR" "$WORK_DIR"
}

# Helper: create an artifact with given status
create_artifact() {
  local path="$1"
  local status="$2"
  mkdir -p "$(dirname "$path")"
  printf -- '---\nstatus: %s\n---\nContent\n' "$status" > "$path"
}

# Helper: init state.json by sourcing pipeline lib and calling state_init_or_reconcile
init_state() {
  local artifact_dir="$1"
  # Source pipeline lib which sources state.sh which sources frontmatter.sh
  PIPELINE_LIB="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
  bash -c "source '$PIPELINE_LIB'; cd '$WORK_DIR'; state_init_or_reconcile '$artifact_dir'"
}

# ──────────────────────────────────────────────────────────────
# Test 1: Write to design.md with goals+questions+research approved → exit 0
# ──────────────────────────────────────────────────────────────
@test "Write to design.md with goals+questions+research approved allows (exit 0)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"new content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 2: Write to design.md with goals draft → exit 2 with "goals" in reason
# ──────────────────────────────────────────────────────────────
@test "Write to design.md with goals draft blocks (exit 2) with goals in reason" {
  create_artifact "$ARTIFACT_DIR/goals.md" "draft"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"new content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# ──────────────────────────────────────────────────────────────
# Test 3: Edit to structure.md with design not approved → exit 2
# ──────────────────────────────────────────────────────────────
@test "Edit to structure.md with design not approved blocks (exit 2)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Edit","tool_input":{"file_path":"'"$ARTIFACT_DIR/structure.md"'","old_string":"old","new_string":"new"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"design"* ]]
}

# ──────────────────────────────────────────────────────────────
# Test 4: Write to non-artifact (hooks/lib/foo.sh) → exit 0
# ──────────────────────────────────────────────────────────────
@test "Write to non-artifact file allows (exit 0)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"/some/project/hooks/lib/foo.sh","content":"#!/bin/bash"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 5: Bash tool call → exit 0
# ──────────────────────────────────────────────────────────────
@test "Bash tool call allows (exit 0)" {
  local json
  json='{"tool_name":"Bash","tool_input":{"command":"echo hello"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 6: Malformed JSON → exit 2 (fail-closed)
# ──────────────────────────────────────────────────────────────
@test "Malformed JSON blocks (exit 2, fail-closed)" {
  run "$HOOK" <<< "this is not json at all"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# Test 7: No state file → exit 0 for artifact writes (no pipeline to enforce yet)
# ──────────────────────────────────────────────────────────────
@test "No state file allows artifact write (no pipeline to enforce yet)" {
  # WORK_DIR has no .qrspi/state.json — no pipeline state means no ordering
  # to enforce. Avoids deadlock where first artifact can never be written.

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 8: stderr message includes next-step instructions on block
# ──────────────────────────────────────────────────────────────
@test "Blocked write emits informative stderr message" {
  create_artifact "$ARTIFACT_DIR/goals.md" "draft"
  create_artifact "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  # stderr (captured in $output when using run without --separate-stderr, but bats merges them)
  # Check that the block JSON reason is meaningful
  [[ "$output" == *"goals"* ]]
  [[ "$output" == *"design"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U1] Unknown tool "Memoize" → exit 0, stdout {}, stderr WARNING
# ──────────────────────────────────────────────────────────────
@test "[T03-U1] Unknown tool name emits warning to stderr and exits 0" {
  local json='{"tool_name":"Memoize","tool_input":{}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"unknown tool_name"* ]]
  [[ "$stderr" == *"Memoize"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U2] Write to goals.md with no state file → exit 0, stderr WARNING
# ──────────────────────────────────────────────────────────────
@test "[T03-U2] Write to goals.md with no state file emits warning and exits 0" {
  # WORK_DIR has no .qrspi/state.json
  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/goals.md"'","content":"x"}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"no state file"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U6] Bash tool_input not an object → exit 2, deny JSON
# ──────────────────────────────────────────────────────────────
@test "[T03-U6] Bash tool_input not an object blocks with deny JSON" {
  local json='{"tool_name":"Bash","tool_input":"not-an-object"}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$stderr" == *"BLOCKED"* ]]
  [[ "$stderr" == *"Cannot parse Bash command"* ]]
  local decision
  decision=$(printf '%s' "$output" | jq -r '.decision')
  [[ "$decision" == "block" ]]
}

# ──────────────────────────────────────────────────────────────
# [runtime] subagent Edit inside worktree allows
# ──────────────────────────────────────────────────────────────
@test "[runtime] subagent Edit inside worktree allows" {
  mkdir -p "$WORK_DIR/.worktrees/myslug/task-01/src"
  mkdir -p "$WORK_DIR/docs/qrspi/2026-04-26-myslug"

  local target="$WORK_DIR/.worktrees/myslug/task-01/src/foo.ts"
  local json='{"agent_id":"sub-1","agent_type":"impl","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] subagent Edit outside worktree blocks
# ──────────────────────────────────────────────────────────────
@test "[runtime] subagent Edit outside worktree blocks" {
  local target="$WORK_DIR/random/foo.ts"
  mkdir -p "$WORK_DIR/random"
  local json='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] main chat Edit anywhere allows
# ──────────────────────────────────────────────────────────────
@test "[runtime] main chat Edit anywhere allows" {
  local target="$WORK_DIR/random/foo.ts"
  mkdir -p "$WORK_DIR/random"
  local json='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] anyone running rm -rf * blocks
# ──────────────────────────────────────────────────────────────
@test "[runtime] anyone running rm -rf * blocks" {
  local json='{"tool_name":"Bash","tool_input":{"command":"rm -rf *"}}'
  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}
