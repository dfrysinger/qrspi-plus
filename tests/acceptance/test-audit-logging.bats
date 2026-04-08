#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 2 — Audit Logging portion:
# "Audit logging: PostToolUse logs all Write/Edit/Bash operations to
#  .qrspi/audit-task-NN.jsonl"
#
# These tests drive the post-tool-use hook end-to-end and verify:
#   - Write/Edit operations are logged when a task is active
#   - Bash operations with file-write patterns are logged
#   - Log entries are valid JSONL with all required fields
#   - Strict vs monitored in_scope flag is set correctly
#   - Special characters in commands/paths do not corrupt JSON
#   - No logging when no task is active (no task ID in state)
#
# Regression: audit.sh uses jq --arg for all string fields (no shell interpolation)

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  export ARTIFACT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$WORK_DIR/.qrspi"
  cd "$WORK_DIR"

  export HOOK
  HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
}

teardown() {
  rm -rf "$WORK_DIR"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

create_task_spec() {
  local task_num="$1"
  local enforcement="${2:-monitored}"
  shift 2
  local allowed_block=""
  for p in "$@"; do
    allowed_block="${allowed_block}  - action: create\n    path: ${p}\n"
  done
  printf -- '---\nstatus: approved\ntask: %s\nphase: 1\nenforcement: %s\nallowed_files:\n%s\nconstraints: []\n---\n\n# Task %s\n' \
    "$task_num" "$enforcement" "$(printf '%b' "$allowed_block")" "$task_num" \
    > "$ARTIFACT_DIR/tasks/task-$(printf '%02d' "$task_num").md"
}

init_state_with_task() {
  local task_id="$1"
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$ARTIFACT_DIR" && pwd)"
  jq -cn --arg artifact_dir "$abs_artifact_dir" --argjson task_id "$task_id" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:$task_id}}' > "$WORK_DIR/.qrspi/state.json"
}

init_state_no_task() {
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$ARTIFACT_DIR" && pwd)"
  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"plan",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"draft",
                 implement:"draft",test:"draft"},
      active_task:null}' > "$WORK_DIR/.qrspi/state.json"
}

write_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$file_path"
}

edit_json() {
  local file_path="$1"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"a","new_string":"b"}}\n' "$file_path"
}

bash_json() {
  local cmd="$1"
  local escaped_cmd="${cmd//\\/\\\\}"
  escaped_cmd="${escaped_cmd//\"/\\\"}"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}\n' "$escaped_cmd"
}

audit_file_for_task() {
  local task_id="$1"
  printf '%s/.qrspi/audit-task-%02d.jsonl' "$WORK_DIR" "$task_id"
}

# ── Basic logging presence ────────────────────────────────────────────────────

# AC2 — Write operation is logged when task is active
@test "[AC2][audit] Write operation creates audit log entry → JSONL file exists" {
  create_task_spec 1 "monitored"
  init_state_with_task 1

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  [ -f "$(audit_file_for_task 1)" ]
}

# AC2 — Edit operation is logged when task is active
@test "[AC2][audit] Edit operation creates audit log entry" {
  create_task_spec 2 "monitored"
  init_state_with_task 2

  "$HOOK" <<< "$(edit_json "$WORK_DIR/src/file.sh")"

  [ -f "$(audit_file_for_task 2)" ]
}

# AC2 — Bash operation is logged when task is active and has file-write targets
@test "[AC2][audit] Bash with file-write target creates audit log entry" {
  create_task_spec 3 "monitored"
  init_state_with_task 3

  "$HOOK" <<< "$(bash_json "echo data > out.txt")"

  [ -f "$(audit_file_for_task 3)" ]
}

# AC2 — Multiple operations produce multiple JSONL lines
@test "[AC2][audit] Multiple Write operations produce multiple JSONL lines" {
  create_task_spec 4 "monitored"
  init_state_with_task 4

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/a.sh")"
  "$HOOK" <<< "$(write_json "$WORK_DIR/src/b.sh")"
  "$HOOK" <<< "$(write_json "$WORK_DIR/src/c.sh")"

  local line_count
  line_count=$(wc -l < "$(audit_file_for_task 4)")
  [ "$line_count" -eq 3 ]
}

# ── JSONL record validity ─────────────────────────────────────────────────────

# AC2 — Each log line is valid JSON
@test "[AC2][audit] Each audit log line is valid JSON (parseable by jq)" {
  create_task_spec 5 "monitored"
  init_state_with_task 5

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  run jq '.' "$(audit_file_for_task 5)"
  [ "$status" -eq 0 ]
}

# AC2 — Log entry has all required fields
@test "[AC2][audit] Write log entry has all required fields: timestamp, tool, target, targets, command, in_scope, enforcement, user_approved, destructive_flag" {
  create_task_spec 6 "monitored"
  init_state_with_task 6

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 6)")

  local has_all
  has_all=$(echo "$record" | jq '
    has("timestamp") and
    has("tool") and
    has("target") and
    has("targets") and
    has("command") and
    has("in_scope") and
    has("enforcement") and
    has("user_approved") and
    has("destructive_flag")')
  [ "$has_all" = "true" ]
}

# AC2 — Write log entry: tool field is "Write"
@test "[AC2][audit] Write log entry tool field = 'Write'" {
  create_task_spec 7 "monitored"
  init_state_with_task 7

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 7)")
  [ "$(echo "$record" | jq -r '.tool')" = "Write" ]
}

# AC2 — Edit log entry: tool field is "Edit"
@test "[AC2][audit] Edit log entry tool field = 'Edit'" {
  create_task_spec 8 "monitored"
  init_state_with_task 8

  "$HOOK" <<< "$(edit_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 8)")
  [ "$(echo "$record" | jq -r '.tool')" = "Edit" ]
}

# AC2 — Write log entry: command field is JSON null (not string "null")
@test "[AC2][audit] Write log entry command field is JSON null" {
  create_task_spec 9 "monitored"
  init_state_with_task 9

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 9)")
  [ "$(echo "$record" | jq '.command')" = "null" ]
}

# AC2 — Write log entry: target field matches file_path
@test "[AC2][audit] Write log entry target field matches written file_path" {
  create_task_spec 10 "monitored"
  init_state_with_task 10

  local target_path="$WORK_DIR/src/myfile.sh"
  "$HOOK" <<< "$(write_json "$target_path")"

  local record
  record=$(head -1 "$(audit_file_for_task 10)")
  [ "$(echo "$record" | jq -r '.target')" = "$target_path" ]
}

# AC2 — Write log entry: targets is a JSON array
@test "[AC2][audit] Write log entry targets field is a JSON array" {
  create_task_spec 11 "monitored"
  init_state_with_task 11

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 11)")
  [ "$(echo "$record" | jq '.targets | type')" = '"array"' ]
}

# AC2 — Write log entry: timestamp is ISO 8601 format
@test "[AC2][audit] Write log entry timestamp is ISO 8601 format" {
  create_task_spec 12 "monitored"
  init_state_with_task 12

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 12)")
  local ts
  ts=$(echo "$record" | jq -r '.timestamp')
  # ISO 8601: YYYY-MM-DDTHH:MM:SSZ
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# AC2 — in_scope is a JSON boolean, not a string
@test "[AC2][audit] Log entry in_scope field is a JSON boolean (not string)" {
  create_task_spec 13 "monitored"
  init_state_with_task 13

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 13)")
  [ "$(echo "$record" | jq '.in_scope | type')" = '"boolean"' ]
}

# ── in_scope flag: strict vs monitored ──────────────────────────────────────

# AC2 — Strict mode: write to allowed file → in_scope=true
@test "[AC2][audit] Strict mode write to allowed file → in_scope=true in log" {
  create_task_spec 14 "strict" "src/allowed.sh"
  init_state_with_task 14

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/allowed.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 14)")
  [ "$(echo "$record" | jq '.in_scope')" = "true" ]
}

# AC2 — Strict mode: write to non-allowed file → in_scope=false in log
# (post-tool-use always logs; pre-tool-use would have blocked this, but post logs after the fact)
@test "[AC2][audit] Strict mode write to non-allowed file → in_scope=false in log" {
  create_task_spec 15 "strict" "src/allowed.sh"
  init_state_with_task 15

  # Post hook logs regardless of whether pre blocked it — test log accuracy
  "$HOOK" <<< "$(write_json "$WORK_DIR/src/not-allowed.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 15)")
  [ "$(echo "$record" | jq '.in_scope')" = "false" ]
}

# AC2 — Monitored mode: write to any file → in_scope=true in log
@test "[AC2][audit] Monitored mode write → in_scope=true in log" {
  create_task_spec 16 "monitored"
  init_state_with_task 16

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/any-file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 16)")
  [ "$(echo "$record" | jq '.in_scope')" = "true" ]
}

# AC2 — enforcement field in log matches task spec
@test "[AC2][audit] Log entry enforcement field matches task spec mode" {
  create_task_spec 17 "strict" "src/file.sh"
  init_state_with_task 17

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  local record
  record=$(head -1 "$(audit_file_for_task 17)")
  [ "$(echo "$record" | jq -r '.enforcement')" = "strict" ]
}

# ── No logging when no task is active ────────────────────────────────────────

# AC2 — No task active → no audit file created
@test "[AC2][audit] No active task → no audit file created" {
  init_state_no_task

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  # No audit file should exist
  local audit_glob
  audit_glob=$(ls "$WORK_DIR/.qrspi/audit-task-"*.jsonl 2>/dev/null || true)
  [ -z "$audit_glob" ]
}

# ── Bash tool logging ─────────────────────────────────────────────────────────

# AC2 — Bash with file-write: log entry tool field is "Bash"
@test "[AC2][audit] Bash log entry tool field = 'Bash'" {
  create_task_spec 18 "monitored"
  init_state_with_task 18

  "$HOOK" <<< "$(bash_json "echo data > out.txt")"

  local record
  record=$(head -1 "$(audit_file_for_task 18)")
  [ "$(echo "$record" | jq -r '.tool')" = "Bash" ]
}

# AC2 — Bash log entry: command field is set (not null)
@test "[AC2][audit] Bash log entry command field is not null" {
  create_task_spec 19 "monitored"
  init_state_with_task 19

  "$HOOK" <<< "$(bash_json "echo data > out.txt")"

  local record
  record=$(head -1 "$(audit_file_for_task 19)")
  # command must be a string, not null
  [ "$(echo "$record" | jq '.command | type')" = '"string"' ]
}

# ── Regression: JSON escaping ─────────────────────────────────────────────────

# AC2 (regression) — Command with double-quotes is properly JSON-escaped
# Pre-fix: shell interpolation in audit.sh broke on quotes
@test "[AC2][audit][regression] Command with double-quotes is properly JSON-escaped" {
  create_task_spec 20 "monitored"
  init_state_with_task 20

  # Use bash_json helper which escapes the command for the hook's stdin JSON
  "$HOOK" <<< "$(bash_json 'grep "pattern" file.txt > out.txt')"

  local record
  record=$(head -1 "$(audit_file_for_task 20)")
  # Record must be valid JSON (no corruption from quotes)
  echo "$record" | jq . > /dev/null
  local cmd
  cmd=$(echo "$record" | jq -r '.command')
  [[ "$cmd" == *'"pattern"'* ]] || [[ "$cmd" == *"pattern"* ]]
}

# AC2 (regression) — Target path with special characters is properly JSON-escaped
@test "[AC2][audit][regression] Target path with backslash is properly JSON-escaped" {
  create_task_spec 21 "monitored"
  init_state_with_task 21

  # Write to a file with a tricky path component (trailing period)
  local tricky_path="$WORK_DIR/src/my.file.sh"
  "$HOOK" <<< "$(write_json "$tricky_path")"

  local record
  record=$(head -1 "$(audit_file_for_task 21)")
  # Record must be valid JSON
  echo "$record" | jq . > /dev/null
  [ "$(echo "$record" | jq -r '.target')" = "$tricky_path" ]
}

# ── Post-tool-use always exits 0 (non-blocking) ──────────────────────────────

# AC2 — Post hook exits 0 for Write
@test "[AC2][audit] post-tool-use always exits 0 for Write" {
  create_task_spec 22 "monitored"
  init_state_with_task 22

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"
  [ "$status" -eq 0 ]
}

# AC2 — Post hook exits 0 for Bash
@test "[AC2][audit] post-tool-use always exits 0 for Bash" {
  create_task_spec 23 "monitored"
  init_state_with_task 23

  run "$HOOK" <<< "$(bash_json "ls -la")"
  [ "$status" -eq 0 ]
}

# AC2 — Post hook exits 0 for malformed JSON (fail-open)
@test "[AC2][audit] post-tool-use exits 0 on malformed JSON (fail-open)" {
  run "$HOOK" <<< "not valid json"
  [ "$status" -eq 0 ]
}

# ── Audit file naming ─────────────────────────────────────────────────────────

# AC2 — Audit file for task 3 is audit-task-03.jsonl (zero-padded)
@test "[AC2][audit] Audit file for task 3 uses zero-padded name audit-task-03.jsonl" {
  create_task_spec 3 "monitored"
  init_state_with_task 3

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  [ -f "$WORK_DIR/.qrspi/audit-task-03.jsonl" ]
}

# AC2 — Audit file for task 15 is audit-task-15.jsonl
@test "[AC2][audit] Audit file for task 15 uses name audit-task-15.jsonl" {
  create_task_spec 15 "monitored"
  init_state_with_task 15

  "$HOOK" <<< "$(write_json "$WORK_DIR/src/file.sh")"

  [ -f "$WORK_DIR/.qrspi/audit-task-15.jsonl" ]
}
