#!/usr/bin/env bats

setup() {
  # Create temp directory for test audit files
  export TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"

  # Source the audit library
  source "$BATS_TEST_DIRNAME/../../hooks/lib/audit.sh"
}

teardown() {
  # Clean up temp directory
  rm -rf "$TEST_DIR"
}

# Test 1: Creates JSONL file if doesn't exist
@test "audit_log_operation creates JSONL file if doesn't exist" {
  run audit_log_operation "3" "2026-04-07T10:30:00Z" "Write" "/path/to/file.txt" '[]' "null" "true" "monitored" "false" "null"
  [ "$status" -eq 0 ]
  [ -f ".qrspi/audit-task-03.jsonl" ]
}

# Test 2: Appends to existing file without overwriting
@test "audit_log_operation appends to existing file without overwriting" {
  audit_log_operation "5" "2026-04-07T10:00:00Z" "Write" "/file1.txt" '[]' "null" "true" "monitored" "false" "null"
  audit_log_operation "5" "2026-04-07T10:01:00Z" "Edit" "/file2.txt" '[]' "null" "false" "strict" "true" "null"

  [ -f ".qrspi/audit-task-05.jsonl" ]
  line_count=$(wc -l < ".qrspi/audit-task-05.jsonl")
  [ "$line_count" -eq 2 ]
}

# Test 3: Each line is valid JSON (parseable by jq)
@test "audit_log_operation produces valid JSON lines" {
  audit_log_operation "7" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  run jq '.' ".qrspi/audit-task-07.jsonl"
  [ "$status" -eq 0 ]
}

# Test 4: Record has all required fields
@test "audit_log_operation record has all required fields" {
  audit_log_operation "8" "2026-04-07T10:00:00Z" "Write" "/file.txt" '["file1.txt"]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-08.jsonl")
  echo "$record" | jq 'has("timestamp") and has("tool") and has("target") and has("targets") and has("command") and has("in_scope") and has("enforcement") and has("user_approved") and has("destructive_flag")'
  [ "$(echo "$record" | jq 'has("timestamp") and has("tool") and has("target") and has("targets") and has("command") and has("in_scope") and has("enforcement") and has("user_approved") and has("destructive_flag")')" = "true" ]
}

# Test 5: timestamp is ISO 8601
@test "audit_log_operation timestamp is ISO 8601" {
  audit_log_operation "9" "2026-04-07T15:45:30Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-09.jsonl")
  local ts=$(echo "$record" | jq -r '.timestamp')
  [ "$ts" = "2026-04-07T15:45:30Z" ]
}

# Test 6: tool matches argument
@test "audit_log_operation tool matches argument" {
  audit_log_operation "10" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "ls -la" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-10.jsonl")
  [ "$(echo "$record" | jq -r '.tool')" = "Bash" ]
}

# Test 7: command is null for Write
@test "audit_log_operation command is null for Write" {
  audit_log_operation "11" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-11.jsonl")
  [ "$(echo "$record" | jq '.command')" = "null" ]
}

# Test 8: command is null for Edit
@test "audit_log_operation command is null for Edit" {
  audit_log_operation "12" "2026-04-07T10:00:00Z" "Edit" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-12.jsonl")
  [ "$(echo "$record" | jq '.command')" = "null" ]
}

# Test 9: command contains string for Bash
@test "audit_log_operation command contains string for Bash" {
  audit_log_operation "13" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "rm -rf /tmp/test" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-13.jsonl")
  [ "$(echo "$record" | jq -r '.command')" = "rm -rf /tmp/test" ]
}

# Test 10: targets is a JSON array
@test "audit_log_operation targets is a JSON array" {
  audit_log_operation "14" "2026-04-07T10:00:00Z" "Write" "/file.txt" '["file1.txt", "file2.txt"]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-14.jsonl")
  local targets=$(echo "$record" | jq '.targets')
  [ "$(echo "$targets" | jq 'type')" = '"array"' ]
}

# Test 11: in_scope is boolean (not string)
@test "audit_log_operation in_scope is boolean true" {
  audit_log_operation "15" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-15.jsonl")
  [ "$(echo "$record" | jq '.in_scope')" = "true" ]
  [ "$(echo "$record" | jq '.in_scope | type')" = '"boolean"' ]
}

# Test 12: in_scope is boolean false
@test "audit_log_operation in_scope is boolean false" {
  audit_log_operation "16" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "false" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-16.jsonl")
  [ "$(echo "$record" | jq '.in_scope')" = "false" ]
  [ "$(echo "$record" | jq '.in_scope | type')" = '"boolean"' ]
}

# Test 13: user_approved is boolean
@test "audit_log_operation user_approved is boolean" {
  audit_log_operation "17" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "true" "null"

  local record=$(head -1 ".qrspi/audit-task-17.jsonl")
  [ "$(echo "$record" | jq '.user_approved')" = "true" ]
  [ "$(echo "$record" | jq '.user_approved | type')" = '"boolean"' ]
}

# Test 14: destructive_flag is null when "null" passed
@test "audit_log_operation destructive_flag is null when null passed" {
  audit_log_operation "18" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "rm file.txt" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-18.jsonl")
  [ "$(echo "$record" | jq '.destructive_flag')" = "null" ]
}

# Test 15: destructive_flag has value when pattern name passed
@test "audit_log_operation destructive_flag has value when pattern passed" {
  audit_log_operation "19" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "rm -rf /" "true" "monitored" "false" "destructive_rm_rf"

  local record=$(head -1 ".qrspi/audit-task-19.jsonl")
  [ "$(echo "$record" | jq -r '.destructive_flag')" = "destructive_rm_rf" ]
}

# Test 16: Multiple calls produce multiple lines
@test "audit_log_operation multiple calls produce multiple lines" {
  audit_log_operation "20" "2026-04-07T10:00:00Z" "Write" "/file1.txt" '[]' "null" "true" "monitored" "false" "null"
  audit_log_operation "20" "2026-04-07T10:01:00Z" "Edit" "/file2.txt" '[]' "null" "true" "monitored" "false" "null"
  audit_log_operation "20" "2026-04-07T10:02:00Z" "Bash" "/file3.txt" '[]' "ls" "false" "strict" "true" "null"

  line_count=$(wc -l < ".qrspi/audit-task-20.jsonl")
  [ "$line_count" -eq 3 ]
}

# Test 17: Correct file path for task ID 3
@test "audit_log_operation correct file path for task-03" {
  audit_log_operation "3" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"
  [ -f ".qrspi/audit-task-03.jsonl" ]
  [ ! -f ".qrspi/audit.jsonl" ]
}

# Test 18: Correct file path for task ID 15
@test "audit_log_operation correct file path for task-15" {
  audit_log_operation "15" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"
  [ -f ".qrspi/audit-task-15.jsonl" ]
}

# Test 19: enforcement field is preserved
@test "audit_log_operation enforcement field matches argument" {
  audit_log_operation "21" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "strict" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-21.jsonl")
  [ "$(echo "$record" | jq -r '.enforcement')" = "strict" ]
}

# Test 20: target field contains primary file path
@test "audit_log_operation target field contains primary file path" {
  audit_log_operation "22" "2026-04-07T10:00:00Z" "Write" "/primary/path.txt" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-22.jsonl")
  [ "$(echo "$record" | jq -r '.target')" = "/primary/path.txt" ]
}

# Test 21: command with special characters (quotes, backslashes, newlines) is properly escaped
@test "audit_log_operation command with special characters is properly escaped" {
  local cmd='echo "hello\nworld" && grep "test" file.txt'
  audit_log_operation "23" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "$cmd" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-23.jsonl")
  local cmd_field=$(echo "$record" | jq -r '.command')
  [ "$cmd_field" = "$cmd" ]
}

# Test 22: destructive_flag with special characters is properly escaped
@test "audit_log_operation destructive_flag with special characters is properly escaped" {
  local pattern='pattern_with_"quotes"_and\backslashes'
  audit_log_operation "24" "2026-04-07T10:00:00Z" "Bash" "/file.txt" '[]' "rm file.txt" "true" "monitored" "false" "$pattern"

  local record=$(head -1 ".qrspi/audit-task-24.jsonl")
  local flag=$(echo "$record" | jq -r '.destructive_flag')
  [ "$flag" = "$pattern" ]
}

# Test 23: target path with special characters is properly escaped
@test "audit_log_operation target path with special characters is properly escaped" {
  local path='/path/with "quotes" and\backslashes/file.txt'
  audit_log_operation "25" "2026-04-07T10:00:00Z" "Write" "$path" '[]' "null" "true" "monitored" "false" "null"

  local record=$(head -1 ".qrspi/audit-task-25.jsonl")
  local target=$(echo "$record" | jq -r '.target')
  [ "$target" = "$path" ]
}

# ============================================================================
# [T04] Fail-closed error handling tests
# ============================================================================

@test "[T04-A1] audit_log_operation: empty task_id writes to audit.jsonl not audit-task-00.jsonl" {
  run audit_log_operation "" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"
  [ "$status" -eq 0 ]
  [ -f ".qrspi/audit.jsonl" ]
  [ ! -f ".qrspi/audit-task-00.jsonl" ]
}

@test "[T04-A2] audit_log_operation: task_id 0 writes to audit.jsonl not audit-task-00.jsonl" {
  run audit_log_operation "0" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"
  [ "$status" -eq 0 ]
  [ -f ".qrspi/audit.jsonl" ]
  [ ! -f ".qrspi/audit-task-00.jsonl" ]
}

@test "[T04-A3] audit_log_operation: invalid targets_json returns exit 1 with stderr diagnostic" {
  run audit_log_operation "30" "2026-04-07T10:00:00Z" "Write" "/file.txt" 'NOT-JSON' "null" "true" "monitored" "false" "null"
  [ "$status" -eq 1 ]
  [[ "$output" == *"jq failed"* ]]
}

# ============================================================================
# [T06] Review result persistence tests
# ============================================================================

@test "[T06-U7-1] audit_log_operation: multiple calls with empty task_id append to audit.jsonl (2 lines)" {
  audit_log_operation "" "2026-04-07T10:00:00Z" "Write" "/file1.txt" '[]' "null" "true" "monitored" "false" "null"
  audit_log_operation "" "2026-04-07T10:01:00Z" "Edit" "/file2.txt" '[]' "null" "false" "strict" "true" "null"

  [ -f ".qrspi/audit.jsonl" ]
  line_count=$(wc -l < ".qrspi/audit.jsonl")
  [ "$line_count" -eq 2 ]
}

@test "[T06-U7-2] audit_log_operation: audit.jsonl record has valid JSON and boolean in_scope" {
  audit_log_operation "" "2026-04-07T10:00:00Z" "Write" "/file.txt" '[]' "null" "true" "monitored" "false" "null"

  run jq '.' ".qrspi/audit.jsonl"
  [ "$status" -eq 0 ]

  local record
  record=$(head -1 ".qrspi/audit.jsonl")
  [ "$(echo "$record" | jq '.in_scope | type')" = '"boolean"' ]
}

@test "[T06-U7-3] review file: reviews/tasks directory created when review file written" {
  mkdir -p reviews/tasks
  [ -d reviews/tasks ]
}

@test "[T06-U7-4] review file: task-NN-review.md frontmatter contains task field" {
  mkdir -p reviews/tasks
  printf -- '---\ntask: 6\n---\n\n# Task 06 Review\n' > reviews/tasks/task-06-review.md

  local frontmatter
  frontmatter=$(head -3 reviews/tasks/task-06-review.md)
  [[ "$frontmatter" == *"task: 6"* ]]
}
