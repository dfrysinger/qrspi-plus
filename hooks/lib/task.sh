#!/usr/bin/env bash
set -euo pipefail

# Source the frontmatter library
source "$(dirname "${BASH_SOURCE[0]}")/frontmatter.sh"

# task_get_spec_path <task_id> <artifact_dir>
# Returns the path to the task spec file with zero-padded ID.
task_get_spec_path() {
  local task_id="$1"
  local artifact_dir="$2"

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  echo "${artifact_dir}/tasks/task-${padded_id}.md"
}

# task_read_runtime_overrides <task_id>
# Reads the runtime overrides file (.qrspi/task-{NN}-runtime.json).
# This file holds mid-task user decisions: approved extra files,
# enforcement mode switches. See enforcement.sh for how it's consumed.
# Returns 1 if not found.
task_read_runtime_overrides() {
  local task_id="$1"

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  local overrides_path=".qrspi/task-${padded_id}-runtime.json"

  if [[ ! -f "$overrides_path" ]]; then
    return 1
  fi

  cat "$overrides_path"
}

# task_write_runtime_overrides <task_id> <json_string>
# Writes the runtime overrides file (.qrspi/task-{NN}-runtime.json)
# atomically (temp file + mv). Creates .qrspi/ if needed.
task_write_runtime_overrides() {
  local task_id="$1"
  local json_string="$2"

  local padded_id
  padded_id=$(printf "%02d" "$task_id")

  # Create .qrspi directory if needed
  mkdir -p .qrspi

  local overrides_path=".qrspi/task-${padded_id}-runtime.json"
  # Write to temp file on the same filesystem so mv is atomic
  # (cross-filesystem mv degrades to copy+delete, not atomic)
  local temp_file
  temp_file=$(mktemp ".qrspi/.task-${padded_id}-runtime.json.XXXXXX")

  printf "%s" "$json_string" > "$temp_file"
  mv "$temp_file" "$overrides_path"
}
