#!/usr/bin/env bash
set -euo pipefail

# Source the frontmatter library
source "$(dirname "${BASH_SOURCE[0]}")/frontmatter.sh"

# task_read_frontmatter <task_file>
# Parses YAML frontmatter from a task spec file.
# Returns JSON with enforcement, allowed_files, and constraints.
task_read_frontmatter() {
  local task_file="$1"

  if [[ ! -f "$task_file" ]]; then
    return 1
  fi

  local enforcement="strict"
  local allowed_files_json="[]"
  local constraints_json="[]"

  # Extract frontmatter block (between --- markers)
  local in_frontmatter=0
  local frontmatter=""
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # First --- marks start
    if [[ $line_num -eq 1 && "$line" == "---" ]]; then
      in_frontmatter=1
      continue
    fi

    # Second --- marks end
    if [[ $in_frontmatter -eq 1 && "$line" == "---" ]]; then
      break
    fi

    # Collect frontmatter lines
    if [[ $in_frontmatter -eq 1 ]]; then
      frontmatter+="$line"$'\n'
    fi
  done < "$task_file"

  # Parse enforcement
  if [[ "$frontmatter" =~ (^|$'\n')enforcement:\ ([a-z]+) ]]; then
    enforcement="${BASH_REMATCH[2]}"
  fi

  # Parse allowed_files array
  local in_allowed_files=0
  local files_array=()

  while IFS= read -r line; do
    # Check if we're at the allowed_files section
    if [[ "$line" =~ ^allowed_files: ]]; then
      in_allowed_files=1
      continue
    fi

    # Exit allowed_files section when we hit a non-indented line or another field
    if [[ $in_allowed_files -eq 1 ]] && [[ "$line" =~ ^[a-z] ]]; then
      in_allowed_files=0
    fi

    # Parse list items
    if [[ $in_allowed_files -eq 1 && "$line" =~ ^[[:space:]]*-[[:space:]]action: ]]; then
      local action_line="$line"
      local action=""
      local path=""

      # Extract action from current line
      if [[ "$action_line" =~ action:[[:space:]]+([a-z]+) ]]; then
        action="${BASH_REMATCH[1]}"
      fi

      # Read the next line for path (should be indented with path:)
      IFS= read -r path_line || break
      if [[ "$path_line" =~ path:[[:space:]]+(.*) ]]; then
        path="${BASH_REMATCH[1]}"
      fi

      # Add to files array
      if [[ -n "$action" && -n "$path" ]]; then
        files_array+=("{\"action\": \"$action\", \"path\": \"$path\"}")
      fi
    fi
  done <<< "$frontmatter"

  # Build allowed_files JSON
  if [[ ${#files_array[@]} -gt 0 ]]; then
    allowed_files_json="["
    for i in "${!files_array[@]}"; do
      allowed_files_json+="${files_array[$i]}"
      if [[ $i -lt $((${#files_array[@]} - 1)) ]]; then
        allowed_files_json+=","
      fi
    done
    allowed_files_json+="]"
  fi

  # Parse constraints array
  local in_constraints=0
  local constraints_array=()

  while IFS= read -r line; do
    # Check if we're at the constraints section
    if [[ "$line" =~ ^constraints: ]]; then
      in_constraints=1
      continue
    fi

    # Exit constraints section when we hit a non-indented line
    if [[ $in_constraints -eq 1 ]] && [[ "$line" =~ ^[a-z] ]]; then
      in_constraints=0
    fi

    # Parse list items
    if [[ $in_constraints -eq 1 && "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      local constraint_text="${BASH_REMATCH[1]}"
      if [[ -n "$constraint_text" ]]; then
        # Escape quotes for JSON
        constraint_text="${constraint_text//\\/\\\\}"
        constraint_text="${constraint_text//\"/\\\"}"
        constraints_array+=("\"$constraint_text\"")
      fi
    fi
  done <<< "$frontmatter"

  # Build constraints JSON
  if [[ ${#constraints_array[@]} -gt 0 ]]; then
    constraints_json="["
    for i in "${!constraints_array[@]}"; do
      constraints_json+="${constraints_array[$i]}"
      if [[ $i -lt $((${#constraints_array[@]} - 1)) ]]; then
        constraints_json+=","
      fi
    done
    constraints_json+="]"
  fi

  # Output as JSON
  jq -n \
    --arg enforcement "$enforcement" \
    --argjson allowed_files "$allowed_files_json" \
    --argjson constraints "$constraints_json" \
    '{enforcement: $enforcement, allowed_files: $allowed_files, constraints: $constraints}'
}

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
