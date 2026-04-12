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
# Test 7: No state file → exit 2 (fail-closed) for artifact writes
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
# [T03-U3] State with malformed active_task → exit 2, deny JSON, stderr ERROR
# ──────────────────────────────────────────────────────────────
@test "[T03-U3] State with malformed active_task blocks with deny JSON" {
  # Create state where active_task is a string, not an object
  mkdir -p "$WORK_DIR/.qrspi"
  printf '{"version":1,"current_step":"implement","artifact_dir":"%s","artifacts":{},"active_task":"not-an-object"}' \
    "$ARTIFACT_DIR" > "$WORK_DIR/.qrspi/state.json"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"/tmp/somefile.txt","content":"x"}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$stderr" == *"ERROR"* ]]
  [[ "$stderr" == *"failed to parse active_task.id"* ]]
  # stdout should be deny JSON
  local decision
  decision=$(printf '%s' "$output" | jq -r '.decision')
  [[ "$decision" == "block" ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U4] State with active_task:null, Bash with targets → exit 0, stderr WARNING
# ──────────────────────────────────────────────────────────────
@test "[T03-U4] Bash with file-write targets but no active task emits warning" {
  mkdir -p "$WORK_DIR/.qrspi"
  printf '{"version":1,"current_step":"implement","artifact_dir":"%s","artifacts":{},"active_task":null}' \
    "$ARTIFACT_DIR" > "$WORK_DIR/.qrspi/state.json"

  local json='{"tool_name":"Bash","tool_input":{"command":"echo hi > /tmp/out.txt"}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"Bash file-write targets detected but no active task ID"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U5] bash_detect_file_writes fails during active task → exit 2, deny JSON
# ──────────────────────────────────────────────────────────────
@test "[T03-U5] bash_detect_file_writes failure during active task blocks" {
  # Create state with active task
  mkdir -p "$WORK_DIR/.qrspi"
  mkdir -p "$ARTIFACT_DIR/tasks"
  printf -- '---\nstatus: approved\ntask: 1\nphase: 1\nenforcement: monitored\nallowed_files:\n  - action: create\n    path: src/main.sh\nconstraints: []\n---\n\n# Task 1\n' \
    > "$ARTIFACT_DIR/tasks/task-01.md"
  printf '{"version":1,"current_step":"implement","artifact_dir":"%s","artifacts":{},"active_task":{"id":1}}' \
    "$ARTIFACT_DIR" > "$WORK_DIR/.qrspi/state.json"

  # Inject a broken bash_detect_file_writes by temporarily replacing the lib file.
  # Save original, replace with broken version, run hook, restore.
  local lib_dir
  lib_dir="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib"
  cp "$lib_dir/bash-detect.sh" "$WORK_DIR/bash-detect-orig.sh"
  printf '#!/usr/bin/env bash\nset -euo pipefail\nbash_detect_file_writes() { return 1; }\n' > "$lib_dir/bash-detect.sh"

  local json='{"tool_name":"Bash","tool_input":{"command":"echo hi > /tmp/out.txt"}}'

  run --separate-stderr "$HOOK" <<< "$json"

  # Restore original immediately
  cp "$WORK_DIR/bash-detect-orig.sh" "$lib_dir/bash-detect.sh"

  [ "$status" -eq 2 ]
  [[ "$stderr" == *"ERROR"* ]]
  [[ "$stderr" == *"bash_detect_file_writes failed"* ]]
  local decision
  decision=$(printf '%s' "$output" | jq -r '.decision')
  [[ "$decision" == "block" ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U6] Bash tool_input not an object → exit 2, deny JSON, stderr ERROR
# ──────────────────────────────────────────────────────────────
@test "[T03-U6] Bash tool_input not an object blocks with deny JSON" {
  local json='{"tool_name":"Bash","tool_input":"not-an-object"}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$stderr" == *"ERROR"* ]]
  [[ "$stderr" == *"failed to parse Bash command"* ]]
  local decision
  decision=$(printf '%s' "$output" | jq -r '.decision')
  [[ "$decision" == "block" ]]
}

# ──────────────────────────────────────────────────────────────
# Post-tool-use tests (T03-U7 through T03-U9)
# ──────────────────────────────────────────────────────────────

# [T03-U7] post-tool-use unknown tool "Memoize" → exit 0, stderr WARNING
@test "[T03-U7] post-tool-use unknown tool emits warning to stderr" {
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
  local json='{"tool_name":"Memoize","tool_input":{}}'

  run --separate-stderr "$POST_HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"unrecognized tool_name"* ]]
  [[ "$stderr" == *"Memoize"* ]]
}

# [T03-U8] post-tool-use Write with no task ID, state present → exit 0, stderr WARNING
@test "[T03-U8] post-tool-use Write with no task ID and state present emits warning" {
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"

  mkdir -p "$WORK_DIR/.qrspi"
  printf '{"version":1,"current_step":"implement","artifact_dir":"%s","artifacts":{},"active_task":null}' \
    "$ARTIFACT_DIR" > "$WORK_DIR/.qrspi/state.json"

  local json='{"tool_name":"Write","tool_input":{"file_path":"/tmp/somefile.txt","content":"x"}}'

  run --separate-stderr "$POST_HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  # Warning should appear in stderr or in audit log
  [[ "$stderr" == *"WARNING"* ]] || [[ "$stderr" == *"no task ID"* ]]
  [[ "$stderr" == *"no task ID resolved"* ]]
}

# [T03-U9] post-tool-use artifact_is_known returns 2 → exit 0, stderr WARNING
@test "[T03-U9] post-tool-use artifact_is_known error emits warning" {
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"

  mkdir -p "$WORK_DIR/.qrspi"
  printf '{"version":1,"current_step":"implement","artifact_dir":"%s","artifacts":{},"active_task":{"id":1}}' \
    "$ARTIFACT_DIR" > "$WORK_DIR/.qrspi/state.json"

  # Inject a broken artifact_is_known by temporarily replacing the lib file
  local lib_dir
  lib_dir="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib"
  cp "$lib_dir/artifact.sh" "$WORK_DIR/artifact-orig.sh"

  # Write a broken artifact.sh that sources pipeline.sh but overrides artifact_is_known
  printf '#!/usr/bin/env bash\nset -euo pipefail\n' > "$lib_dir/artifact.sh"
  printf '_artifact_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"\n' >> "$lib_dir/artifact.sh"
  printf 'source "$_artifact_script_dir/pipeline.sh"\n' >> "$lib_dir/artifact.sh"
  printf 'artifact_is_known() { return 2; }\n' >> "$lib_dir/artifact.sh"
  printf 'artifact_sync_state() { return 0; }\n' >> "$lib_dir/artifact.sh"

  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/goals.md"'","content":"x"}}'

  run --separate-stderr "$POST_HOOK" <<< "$json"

  # Restore original immediately
  cp "$WORK_DIR/artifact-orig.sh" "$lib_dir/artifact.sh"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"artifact_is_known returned error"* ]]
}
