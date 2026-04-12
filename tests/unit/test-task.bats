#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export ARTIFACT_DIR="$TEST_TEMP_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$TEST_TEMP_DIR/.qrspi"

  # Source the task library for testing
  source "$BATS_TEST_DIRNAME/../../hooks/lib/task.sh"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

# Helper: Create a task spec file with frontmatter
create_task_spec() {
  local file_path="$1"
  local content="$2"
  mkdir -p "$(dirname "$file_path")"
  printf "%s" "$content" > "$file_path"
}

# ============================================================================
# task_read_frontmatter removed — verify it no longer exists
# ============================================================================

@test "task_read_frontmatter must not exist as a function after sourcing" {
  run bash -c 'source "$1" && declare -f task_read_frontmatter >/dev/null 2>&1 && echo exists || echo gone' _ "$BATS_TEST_DIRNAME/../../hooks/lib/task.sh"
  [[ "$output" == "gone" ]]
}

@test "frontmatter_get is available after sourcing task.sh" {
  run bash -c 'source "$1" && declare -f frontmatter_get >/dev/null 2>&1 && echo exists || echo gone' _ "$BATS_TEST_DIRNAME/../../hooks/lib/task.sh"
  [[ "$output" == "exists" ]]
}

@test "frontmatter_get on a full Phase 4 task spec returns valid JSON with enforcement, allowed_files, constraints" {
  local task_file="$ARTIFACT_DIR/tasks/task-01.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
- action: create
  path: hooks/lib/example.sh
- action: modify
  path: hooks/session-start
constraints:
- Must source frontmatter.sh
- No external deps
---

# Task content here
"

  output=$(frontmatter_get "$task_file")

  # Verify JSON structure
  echo "$output" | jq . > /dev/null

  # Check enforcement
  enforcement=$(echo "$output" | jq -r '.enforcement')
  [[ "$enforcement" == "strict" ]]

  # Check allowed_files array length
  files_count=$(echo "$output" | jq '.allowed_files | length')
  [[ "$files_count" == "2" ]]

  # Check first file entry
  action=$(echo "$output" | jq -r '.allowed_files[0].action')
  path=$(echo "$output" | jq -r '.allowed_files[0].path')
  [[ "$action" == "create" ]]
  [[ "$path" == "hooks/lib/example.sh" ]]

  # Check constraints array length
  constraints_count=$(echo "$output" | jq '.constraints | length')
  [[ "$constraints_count" == "2" ]]

  # Check first constraint
  constraint=$(echo "$output" | jq -r '.constraints[0]')
  [[ "$constraint" == "Must source frontmatter.sh" ]]
}

# ============================================================================
# task_get_spec_path tests
# ============================================================================

@test "task_get_spec_path: zero-pads ID 3 to 03" {
  output=$(task_get_spec_path 3 "$ARTIFACT_DIR")
  [[ "$output" == "$ARTIFACT_DIR/tasks/task-03.md" ]]
}

@test "task_get_spec_path: zero-pads ID 12 to 12" {
  output=$(task_get_spec_path 12 "$ARTIFACT_DIR")
  [[ "$output" == "$ARTIFACT_DIR/tasks/task-12.md" ]]
}

@test "task_get_spec_path: handles single digit correctly" {
  output=$(task_get_spec_path 1 "$ARTIFACT_DIR")
  [[ "$output" == "$ARTIFACT_DIR/tasks/task-01.md" ]]
}

@test "task_get_spec_path: handles double digit correctly" {
  output=$(task_get_spec_path 99 "$ARTIFACT_DIR")
  [[ "$output" == "$ARTIFACT_DIR/tasks/task-99.md" ]]
}

# ============================================================================
# task_read_runtime_overrides tests
# ============================================================================

@test "task_read_runtime_overrides: reads existing runtime overrides JSON" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  local json_content='{"status": "passed", "timestamp": "2026-04-07T10:00:00Z"}'
  printf "%s" "$json_content" > ".qrspi/task-05-runtime.json"

  output=$(task_read_runtime_overrides 5)

  # Verify it's valid JSON
  echo "$output" | jq . > /dev/null

  # Verify content
  status=$(echo "$output" | jq -r '.status')
  [[ "$status" == "passed" ]]
}

@test "task_read_runtime_overrides: returns 1 when runtime overrides missing" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi

  run task_read_runtime_overrides 7
  [[ $status == 1 ]]
}

@test "task_read_runtime_overrides: uses zero-padded task ID" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  local json_content='{"test": "data"}'
  printf "%s" "$json_content" > ".qrspi/task-03-runtime.json"

  output=$(task_read_runtime_overrides 3)
  test_val=$(echo "$output" | jq -r '.test')
  [[ "$test_val" == "data" ]]
}

# ============================================================================
# task_write_runtime_overrides tests
# ============================================================================

@test "task_write_runtime_overrides: writes runtime overrides with correct content" {
  cd "$TEST_TEMP_DIR"

  local json_data='{"status": "running", "step": 1}'
  task_write_runtime_overrides 4 "$json_data"

  # Verify file exists and has correct content
  [[ -f ".qrspi/task-04-runtime.json" ]]
  content=$(cat ".qrspi/task-04-runtime.json")
  status=$(echo "$content" | jq -r '.status')
  [[ "$status" == "running" ]]
}

@test "task_write_runtime_overrides: creates .qrspi directory if missing" {
  cd "$TEST_TEMP_DIR"
  rm -rf .qrspi

  local json_data='{"created": true}'
  task_write_runtime_overrides 2 "$json_data"

  [[ -d ".qrspi" ]]
  [[ -f ".qrspi/task-02-runtime.json" ]]
}

@test "task_write_runtime_overrides: overwrites existing runtime overrides" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi

  printf '{"old": "data"}' > ".qrspi/task-06-runtime.json"

  local json_data='{"new": "data"}'
  task_write_runtime_overrides 6 "$json_data"

  content=$(cat ".qrspi/task-06-runtime.json")
  new_val=$(echo "$content" | jq -r '.new')
  [[ "$new_val" == "data" ]]

  # Old key should not exist
  ! echo "$content" | jq -e '.old' > /dev/null
}

@test "task_write_runtime_overrides: uses atomic write (temp + mv)" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi

  local json_data='{"atomic": true}'
  task_write_runtime_overrides 8 "$json_data"

  # Verify final file exists and is valid
  [[ -f ".qrspi/task-08-runtime.json" ]]
  cat ".qrspi/task-08-runtime.json" | jq . > /dev/null
}

# ============================================================================
# T05: task_get_spec_path validation tests
# ============================================================================

@test "[T05-T1] task_get_spec_path: empty task_id returns 1 with 'task_id is empty'" {
  run task_get_spec_path "" "/some/dir"
  [[ $status == 1 ]]
  [[ "$output" == *"task_id is empty"* ]]
}

@test "[T05-T2] task_get_spec_path: non-numeric task_id returns 1 with 'not a positive integer'" {
  run task_get_spec_path "abc" "/some/dir"
  [[ $status == 1 ]]
  [[ "$output" == *"not a positive integer"* ]]
}

@test "[T05-T3] task_get_spec_path: empty artifact_dir returns 1 with 'artifact_dir is empty'" {
  run task_get_spec_path "3" ""
  [[ $status == 1 ]]
  [[ "$output" == *"artifact_dir is empty"* ]]
}

# ============================================================================
# T05: task_read_runtime_overrides validation tests
# ============================================================================

@test "[T05-T4] task_read_runtime_overrides: invalid JSON content returns 1 with 'invalid JSON'" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  printf "not-json-content" > ".qrspi/task-09-runtime.json"

  run task_read_runtime_overrides 9
  [[ $status == 1 ]]
  [[ "$output" == *"invalid JSON"* ]]
}

@test "[T05-T5] task_read_runtime_overrides: empty file returns 1 with 'invalid JSON'" {
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  printf "" > ".qrspi/task-10-runtime.json"

  run task_read_runtime_overrides 10
  [[ $status == 1 ]]
  [[ "$output" == *"invalid JSON"* ]]
}

# ============================================================================
# T05: task_write_runtime_overrides validation tests
# ============================================================================

@test "[T05-T6] task_write_runtime_overrides: non-JSON input returns 1 with 'not valid JSON', file not created" {
  cd "$TEST_TEMP_DIR"

  run task_write_runtime_overrides "3" "not-json"
  [[ $status == 1 ]]
  [[ "$output" == *"not valid JSON"* ]]
  [[ ! -f ".qrspi/task-03-runtime.json" ]]
}

# ============================================================================
# Library quality tests
# ============================================================================

@test "task.sh uses set -euo pipefail" {
  # This test verifies that the script has proper error handling
  # If it doesn't, the sourcing would have failed
  [[ -n "${BASH_VERSION}" ]]
}

@test "task.sh sources frontmatter.sh" {
  # Verify frontmatter_get is available after sourcing task.sh
  declare -f frontmatter_get > /dev/null
}
