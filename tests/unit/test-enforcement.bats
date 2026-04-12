#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export ARTIFACT_DIR="$TEST_TEMP_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$TEST_TEMP_DIR/.qrspi"

  # Source the enforcement library
  source "$BATS_TEST_DIRNAME/../../hooks/lib/enforcement.sh"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

# Helper: create task spec file
create_task_spec() {
  local file_path="$1"
  local content="$2"
  mkdir -p "$(dirname "$file_path")"
  printf "%s" "$content" > "$file_path"
}

# ============================================================================
# enforcement_get_mode tests
# ============================================================================

@test "enforcement_get_mode: returns task spec value when no runtime overrides" {
  local task_file="$ARTIFACT_DIR/tasks/task-01.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 1
"
  cd "$TEST_TEMP_DIR"
  result=$(enforcement_get_mode 1 "$ARTIFACT_DIR")
  [[ "$result" == "strict" ]]
}

@test "enforcement_get_mode: returns monitored from task spec" {
  local task_file="$ARTIFACT_DIR/tasks/task-02.md"
  create_task_spec "$task_file" "---
enforcement: monitored
allowed_files: []
constraints: []
---

# Task 2
"
  cd "$TEST_TEMP_DIR"
  result=$(enforcement_get_mode 2 "$ARTIFACT_DIR")
  [[ "$result" == "monitored" ]]
}

@test "enforcement_get_mode: runtime overrides override takes precedence over task spec" {
  local task_file="$ARTIFACT_DIR/tasks/task-03.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files: []
constraints: []
---

# Task 3
"
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  printf '{"enforcement":"monitored","user_approved_files":[]}' > ".qrspi/task-03-runtime.json"

  result=$(enforcement_get_mode 3 "$ARTIFACT_DIR")
  [[ "$result" == "monitored" ]]
}

@test "enforcement_get_mode: no Phase 4 fields defaults to strict (fail-closed)" {
  local task_file="$ARTIFACT_DIR/tasks/task-04.md"
  create_task_spec "$task_file" "---
title: Old-style task
---

# Task 4
"
  cd "$TEST_TEMP_DIR"
  result=$(enforcement_get_mode 4 "$ARTIFACT_DIR")
  [[ "$result" == "strict" ]]
}

# ============================================================================
# enforcement_check_allowlist tests
# ============================================================================

@test "enforcement_check_allowlist: file in allowed_files returns 0 in strict mode" {
  local task_file="$ARTIFACT_DIR/tasks/task-05.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 5
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "hooks/lib/enforcement.sh" 5 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

@test "enforcement_check_allowlist: file NOT in allowed_files returns 2 in strict mode" {
  local task_file="$ARTIFACT_DIR/tasks/task-06.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 6
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "some/other/file.sh" 6 "$ARTIFACT_DIR"
  [[ $status -eq 2 ]]
}

@test "enforcement_check_allowlist: file in runtime overrides user_approved_files returns 0 in strict mode" {
  local task_file="$ARTIFACT_DIR/tasks/task-07.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 7
"
  cd "$TEST_TEMP_DIR"
  mkdir -p .qrspi
  printf '{"enforcement":"strict","user_approved_files":["extra/file.sh"]}' > ".qrspi/task-07-runtime.json"

  run enforcement_check_allowlist "extra/file.sh" 7 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

@test "enforcement_check_allowlist: any file in monitored mode returns 0" {
  local task_file="$ARTIFACT_DIR/tasks/task-08.md"
  create_task_spec "$task_file" "---
enforcement: monitored
allowed_files: []
constraints: []
---

# Task 8
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "any/random/file.sh" 8 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

@test "enforcement_check_allowlist: pre-Phase-4 task defaults to strict (fail-closed), blocks" {
  local task_file="$ARTIFACT_DIR/tasks/task-09.md"
  create_task_spec "$task_file" "---
title: Old-style task
---

# Task 9
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "any/file.sh" 9 "$ARTIFACT_DIR"
  [[ $status -eq 2 ]]
}

@test "enforcement_check_allowlist: strict block writes message with approve, switch, reject to stderr" {
  local task_file="$ARTIFACT_DIR/tasks/task-10.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 10
"
  cd "$TEST_TEMP_DIR"
  local stderr_file="$TEST_TEMP_DIR/stderr.txt"

  enforcement_check_allowlist "blocked/file.sh" 10 "$ARTIFACT_DIR" 2>"$stderr_file" || true

  stderr_content=$(cat "$stderr_file")
  [[ "$stderr_content" == *"approve"* ]]
  [[ "$stderr_content" == *"switch"* ]]
  [[ "$stderr_content" == *"reject"* ]]
}

@test "enforcement_check_allowlist: strict block message mentions file path" {
  local task_file="$ARTIFACT_DIR/tasks/task-11.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 11
"
  cd "$TEST_TEMP_DIR"
  local stderr_file="$TEST_TEMP_DIR/stderr.txt"

  enforcement_check_allowlist "blocked/my-file.sh" 11 "$ARTIFACT_DIR" 2>"$stderr_file" || true

  stderr_content=$(cat "$stderr_file")
  [[ "$stderr_content" == *"blocked/my-file.sh"* ]]
}

@test "enforcement_check_allowlist: allowlist handles both create and modify actions" {
  local task_file="$ARTIFACT_DIR/tasks/task-12.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: new-file.sh
  - action: modify
    path: existing-file.sh
constraints: []
---

# Task 12
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "new-file.sh" 12 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]

  run enforcement_check_allowlist "existing-file.sh" 12 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

@test "enforcement_check_allowlist: absolute file path does NOT match relative allowlist entry (pre-resolve required)" {
  local task_file="$ARTIFACT_DIR/tasks/task-13.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: hooks/lib/enforcement.sh
constraints: []
---

# Task 13
"
  cd "$TEST_TEMP_DIR"
  # Allowlist has relative path but we pass absolute path — no match expected.
  # Paths must be pre-resolved to absolute via task_resolve_allowlist_paths before
  # enforcement_check_allowlist is called; direct string comparison is used.
  run enforcement_check_allowlist "$TEST_TEMP_DIR/hooks/lib/enforcement.sh" 13 "$ARTIFACT_DIR"
  [[ $status -eq 2 ]]
}

# ============================================================================
# U10: Pre-resolved absolute path matching tests
# ============================================================================

@test "[U10-T1] enforcement_check_allowlist: pre-resolved absolute path matches allowlist entry" {
  local task_file="$ARTIFACT_DIR/tasks/task-14.md"
  local abs_path="/resolved/absolute/hooks/lib/enforcement.sh"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: /resolved/absolute/hooks/lib/enforcement.sh
constraints: []
---

# Task 14
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "$abs_path" 14 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

@test "[U10-T2] enforcement_check_allowlist: pre-resolved absolute path not in allowlist returns 2" {
  local task_file="$ARTIFACT_DIR/tasks/task-15.md"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: create
    path: /resolved/absolute/hooks/lib/enforcement.sh
constraints: []
---

# Task 15
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "/some/other/absolute/path.sh" 15 "$ARTIFACT_DIR"
  [[ $status -eq 2 ]]
}

@test "[U10-T3] enforcement_check_allowlist does not contain realpath/readlink/pwd path-resolution logic" {
  local script_path="$BATS_TEST_DIRNAME/../../hooks/lib/enforcement.sh"
  # None of these path-resolution commands should appear in enforcement_check_allowlist
  # (they should only be in task.sh now)
  ! grep -q "realpath\|readlink\|cwd=\$(pwd)" "$script_path"
}

@test "[U10-T4] enforcement_check_allowlist: direct string comparison matches identical absolute paths" {
  local task_file="$ARTIFACT_DIR/tasks/task-16.md"
  local abs_path="/absolute/path/to/file.sh"
  create_task_spec "$task_file" "---
enforcement: strict
allowed_files:
  - action: modify
    path: /absolute/path/to/file.sh
constraints: []
---

# Task 16
"
  cd "$TEST_TEMP_DIR"
  run enforcement_check_allowlist "$abs_path" 16 "$ARTIFACT_DIR"
  [[ $status -eq 0 ]]
}

# ============================================================================
# Library quality tests
# ============================================================================

@test "enforcement.sh uses set -euo pipefail" {
  # Verify the script exists and has pipefail enabled (presence of the header)
  grep -q "set -euo pipefail" "$BATS_TEST_DIRNAME/../../hooks/lib/enforcement.sh"
}

@test "enforcement.sh sources task.sh" {
  # Verify frontmatter_get is available after sourcing enforcement.sh (via task.sh)
  declare -f frontmatter_get > /dev/null
}
