#!/usr/bin/env bash
set -euo pipefail

# Source the task library for task ID resolution
source "$(dirname "${BASH_SOURCE[0]}")/task.sh"

# audit_log_operation <task_id> <timestamp> <tool> <target> <targets_json> <command> <in_scope> <enforcement> <user_approved> <destructive_flag>
#
# Appends a single JSON line to .qrspi/audit-task-NN.jsonl (NN = zero-padded task_id).
#
# Arguments:
#   task_id          - Task ID (e.g., 3, 15)
#   timestamp        - ISO 8601 timestamp
#   tool             - "Write", "Edit", or "Bash"
#   target           - Primary file path (string)
#   targets_json     - JSON array of all target paths
#   command          - Full command string for Bash, "null" for Write/Edit
#   in_scope         - "true" or "false" string
#   enforcement      - "strict" or "monitored"
#   user_approved    - "true" or "false" string
#   destructive_flag - Pattern name or "null" string
#
audit_log_operation() {
  local task_id="$1"
  local timestamp="$2"
  local tool="$3"
  local target="$4"
  local targets_json="$5"
  local command="$6"
  local in_scope="$7"
  local enforcement="$8"
  local user_approved="$9"
  local destructive_flag="${10}"

  # Create .qrspi directory if it doesn't exist
  mkdir -p .qrspi

  # Convert task_id to zero-padded format (e.g., 3 -> 03, 15 -> 15)
  local padded_task_id=$(printf "%02d" "$task_id")
  local audit_file=".qrspi/audit-task-${padded_task_id}.jsonl"

  # Sanitize boolean inputs: ensure they are exactly "true" or "false"
  # so jq's --argjson can parse them as JSON booleans (not strings).
  # Without this, an unexpected value like "yes" or "" would crash jq.
  local in_scope_bool=$([ "$in_scope" = "true" ] && echo "true" || echo "false")
  local user_approved_bool=$([ "$user_approved" = "true" ] && echo "true" || echo "false")

  # Build the JSON record using jq with proper escaping
  local json_record
  if [ "$command" = "null" ] && [ "$destructive_flag" = "null" ]; then
    json_record=$(jq -cn \
      --arg timestamp "$timestamp" \
      --arg tool "$tool" \
      --arg target "$target" \
      --argjson targets "$targets_json" \
      --arg enforcement "$enforcement" \
      --argjson in_scope "$in_scope_bool" \
      --argjson user_approved "$user_approved_bool" \
      '{timestamp: $timestamp, tool: $tool, target: $target, targets: $targets, command: null, in_scope: $in_scope, enforcement: $enforcement, user_approved: $user_approved, destructive_flag: null}')
  elif [ "$command" = "null" ]; then
    json_record=$(jq -cn \
      --arg timestamp "$timestamp" \
      --arg tool "$tool" \
      --arg target "$target" \
      --argjson targets "$targets_json" \
      --arg enforcement "$enforcement" \
      --argjson in_scope "$in_scope_bool" \
      --argjson user_approved "$user_approved_bool" \
      --arg destructive_flag "$destructive_flag" \
      '{timestamp: $timestamp, tool: $tool, target: $target, targets: $targets, command: null, in_scope: $in_scope, enforcement: $enforcement, user_approved: $user_approved, destructive_flag: $destructive_flag}')
  elif [ "$destructive_flag" = "null" ]; then
    json_record=$(jq -cn \
      --arg timestamp "$timestamp" \
      --arg tool "$tool" \
      --arg target "$target" \
      --argjson targets "$targets_json" \
      --arg command "$command" \
      --arg enforcement "$enforcement" \
      --argjson in_scope "$in_scope_bool" \
      --argjson user_approved "$user_approved_bool" \
      '{timestamp: $timestamp, tool: $tool, target: $target, targets: $targets, command: $command, in_scope: $in_scope, enforcement: $enforcement, user_approved: $user_approved, destructive_flag: null}')
  else
    json_record=$(jq -cn \
      --arg timestamp "$timestamp" \
      --arg tool "$tool" \
      --arg target "$target" \
      --argjson targets "$targets_json" \
      --arg command "$command" \
      --arg enforcement "$enforcement" \
      --argjson in_scope "$in_scope_bool" \
      --argjson user_approved "$user_approved_bool" \
      --arg destructive_flag "$destructive_flag" \
      '{timestamp: $timestamp, tool: $tool, target: $target, targets: $targets, command: $command, in_scope: $in_scope, enforcement: $enforcement, user_approved: $user_approved, destructive_flag: $destructive_flag}')
  fi

  # Append to file
  echo "$json_record" >> "$audit_file"
}
