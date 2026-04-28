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

# task_resolve_allowlist_paths <allowed_files_json> <base_dir>
# Resolves each path in an allowed_files JSON array to its absolute canonical form.
# Relative paths are resolved relative to base_dir. Already-absolute paths pass through.
# Tilde expansion is handled via bash parameter expansion.
# Uses realpath --no-symlinks if available, falls back to readlink -f.
# Writes the resolved array to .qrspi/resolved-allowlist-paths.json (runtime sidecar).
# Outputs the updated JSON array on stdout.
task_resolve_allowlist_paths() {
  local allowed_files_json="$1"
  local base_dir="$2"

  local resolved_json
  resolved_json="[]"

  local count
  count=$(printf "%s" "$allowed_files_json" | jq 'length')

  local i=0
  while [[ $i -lt $count ]]; do
    local entry
    entry=$(printf "%s" "$allowed_files_json" | jq --argjson idx "$i" '.[$idx]')

    local raw_path
    raw_path=$(printf "%s" "$entry" | jq -r '.path')

    # Tilde expansion
    if [[ "$raw_path" == "~/"* ]]; then
      raw_path="${HOME}/${raw_path#"~/"}"
    elif [[ "$raw_path" == "~" ]]; then
      raw_path="$HOME"
    fi

    # Resolve to absolute path
    local abs_path
    if [[ "$raw_path" != /* ]]; then
      # Relative path — resolve against base_dir
      local candidate="${base_dir}/${raw_path}"
      if realpath --no-symlinks "$candidate" > /dev/null 2>&1; then
        abs_path=$(realpath --no-symlinks "$candidate")
      elif readlink -f "$candidate" > /dev/null 2>&1; then
        abs_path=$(readlink -f "$candidate")
      else
        abs_path="$candidate"
      fi
    else
      abs_path="$raw_path"
    fi

    local resolved_entry
    resolved_entry=$(printf "%s" "$entry" | jq --arg p "$abs_path" '.path = $p')
    resolved_json=$(printf "%s" "$resolved_json" | jq --argjson e "$resolved_entry" '. + [$e]')

    i=$((i + 1))
  done

  # Write sidecar
  mkdir -p .qrspi
  printf "%s" "$resolved_json" > ".qrspi/resolved-allowlist-paths.json"

  printf "%s" "$resolved_json"
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
