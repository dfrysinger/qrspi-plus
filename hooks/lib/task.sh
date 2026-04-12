#!/usr/bin/env bash
set -euo pipefail

# Source the frontmatter library
source "$(dirname "${BASH_SOURCE[0]}")/frontmatter.sh"

# task_get_spec_path <task_id> <artifact_dir>
# Returns the path to the task spec file with zero-padded ID.
task_get_spec_path() {
  local task_id="$1"
  local artifact_dir="$2"

  if [[ -z "$task_id" ]]; then
    echo "task_id is empty" >&2
    return 1
  fi

  if [[ ! "$task_id" =~ ^[0-9]+$ ]]; then
    echo "task_id is not a positive integer" >&2
    return 1
  fi

  if [[ -z "$artifact_dir" ]]; then
    echo "artifact_dir is empty" >&2
    return 1
  fi

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  echo "${artifact_dir}/tasks/task-${padded_id}.md"
}

# task_read_runtime_overrides <task_id>
# Reads the runtime overrides file (.qrspi/task-{NN}-runtime.json).
# This file holds mid-task user decisions: approved extra files,
# enforcement mode switches. See enforcement.sh for how it's consumed.
# Returns 1 if not found or content is invalid JSON.
task_read_runtime_overrides() {
  local task_id="$1"

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  local overrides_path=".qrspi/task-${padded_id}-runtime.json"

  if [[ ! -f "$overrides_path" ]]; then
    return 1
  fi

  local content
  content=$(cat "$overrides_path") || { echo "failed to read $overrides_path" >&2; return 1; }

  if [[ -z "$content" ]] || ! echo "$content" | jq empty 2>/dev/null; then
    echo "invalid JSON in $overrides_path" >&2
    return 1
  fi

  echo "$content"
}

# task_write_runtime_overrides <task_id> <json_string>
# Writes the runtime overrides file (.qrspi/task-{NN}-runtime.json)
# atomically (temp file + mv). Creates .qrspi/ if needed.
task_write_runtime_overrides() {
  local task_id="$1"
  local json_string="$2"

  if ! echo "$json_string" | jq empty 2>/dev/null; then
    echo "json_string is not valid JSON" >&2
    return 1
  fi

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  # Create .qrspi directory if needed
  mkdir -p .qrspi

  local overrides_path=".qrspi/task-${padded_id}-runtime.json"
  # Write to temp file on the same filesystem so mv is atomic
  # (cross-filesystem mv degrades to copy+delete, not atomic)
  local temp_file
  temp_file=$(mktemp ".qrspi/.task-${padded_id}-runtime.json.XXXXXX") || { echo "failed to create temp file" >&2; return 1; }

  if ! printf "%s" "$json_string" > "$temp_file"; then
    echo "failed to write to temp file $temp_file" >&2
    rm -f "$temp_file"
    return 1
  fi

  if ! mv "$temp_file" "$overrides_path"; then
    echo "failed to move temp file to $overrides_path" >&2
    rm -f "$temp_file"
    return 1
  fi
}
