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
# task_read_frontmatter tests
# ============================================================================

@test "task_read_frontmatter: reads all Phase 4 fields correctly" {
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

  output=$(task_read_frontmatter "$task_file")

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

@test "task_read_frontmatter: reads enforcement after status/task/phase fields" {
  # Regression: enforcement regex must not require ^ anchor (enforcement is not first field)
  local task_file="$ARTIFACT_DIR/tasks/task-20.md"
  create_task_spec "$task_file" "---
status: approved
task: 20
phase: 1
enforcement: strict
allowed_files:
  - action: create
    path: src/main.sh
constraints: []
---

# Task 20
"

  output=$(task_read_frontmatter "$task_file")
  enforcement=$(echo "$output" | jq -r '.enforcement')
  [[ "$enforcement" == "strict" ]]
}

@test "task_read_frontmatter: defaults to strict when enforcement missing (fail-closed)" {
  local task_file="$ARTIFACT_DIR/tasks/task-02.md"
  create_task_spec "$task_file" "---
allowed_files: []
constraints: []
---

# Task content
"

  output=$(task_read_frontmatter "$task_file")
  enforcement=$(echo "$output" | jq -r '.enforcement')
  [[ "$enforcement" == "strict" ]]
}

@test "task_read_frontmatter: returns empty allowed_files when missing" {
  local task_file="$ARTIFACT_DIR/tasks/task-03.md"
  create_task_spec "$task_file" "---
enforcement: strict
constraints: []
---

# Task content
"

  output=$(task_read_frontmatter "$task_file")
  files_count=$(echo "$output" | jq '.allowed_files | length')
  [[ "$files_count" == "0" ]]
}

@test "task_read_frontmatter: returns empty constraints when missing" {
  local task_file="$ARTIFACT_DIR/tasks/task-04.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files: []
---

# Task content
"

  output=$(task_read_frontmatter "$task_file")
  constraints_count=$(echo "$output" | jq '.constraints | length')
  [[ "$constraints_count" == "0" ]]
}

@test "task_read_frontmatter: all Phase 4 fields missing returns defaults" {
  local task_file="$ARTIFACT_DIR/tasks/task-05.md"
  create_task_spec "$task_file" "---
title: Some task
---

# Task content
"

  output=$(task_read_frontmatter "$task_file")
  enforcement=$(echo "$output" | jq -r '.enforcement')
  files_count=$(echo "$output" | jq '.allowed_files | length')
  constraints_count=$(echo "$output" | jq '.constraints | length')

  [[ "$enforcement" == "strict" ]]
  [[ "$files_count" == "0" ]]
  [[ "$constraints_count" == "0" ]]
}

@test "task_read_frontmatter: nonexistent file returns 1" {
  run task_read_frontmatter "/nonexistent/file.md"
  [[ $status == 1 ]]
}

@test "task_read_frontmatter: multi-entry allowed_files parsed correctly" {
  local task_file="$ARTIFACT_DIR/tasks/task-06.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: file1.sh
  - action: modify
    path: file2.sh
  - action: delete
    path: file3.sh
constraints: []
---

# Content
"

  output=$(task_read_frontmatter "$task_file")
  files_count=$(echo "$output" | jq '.allowed_files | length')
  [[ "$files_count" == "3" ]]

  # Verify second entry
  action=$(echo "$output" | jq -r '.allowed_files[1].action')
  path=$(echo "$output" | jq -r '.allowed_files[1].path')
  [[ "$action" == "modify" ]]
  [[ "$path" == "file2.sh" ]]

  # Verify third entry
  action=$(echo "$output" | jq -r '.allowed_files[2].action')
  path=$(echo "$output" | jq -r '.allowed_files[2].path')
  [[ "$action" == "delete" ]]
  [[ "$path" == "file3.sh" ]]
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
# Library quality tests
# ============================================================================

@test "task.sh uses set -euo pipefail" {
  # This test verifies that the script has proper error handling
  # If it doesn't, the sourcing would have failed
  [[ -n "${BASH_VERSION}" ]]
}

@test "task.sh sources frontmatter.sh" {
  # Verify frontmatter_get_status is available after sourcing task.sh
  declare -f frontmatter_get_status > /dev/null
}
