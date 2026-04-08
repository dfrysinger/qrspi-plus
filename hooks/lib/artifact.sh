#!/usr/bin/env bash
set -euo pipefail

# Source pipeline.sh from the same directory
_artifact_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_artifact_script_dir/pipeline.sh"

# ARTIFACT_FILES — array of 6 known artifact paths
declare -a ARTIFACT_FILES=(
  "goals.md"
  "questions.md"
  "research/summary.md"
  "design.md"
  "structure.md"
  "plan.md"
)

# artifact_is_known <file_path> <artifact_dir>
# Checks if file_path matches a known artifact by comparing path suffix.
# Returns 0 with step name on stdout if matched (goals, questions, research, design, structure, plan).
# Returns 1 if not a known artifact.
artifact_is_known() {
  local file_path="$1"
  local artifact_dir="$2"

  # Resolve artifact_dir to absolute path
  artifact_dir=$(cd "$artifact_dir" 2>/dev/null && pwd) || return 1

  # Resolve file_path to absolute path if possible
  local abs_file_path
  if [[ "$file_path" =~ ^/ ]]; then
    abs_file_path="$file_path"
  else
    abs_file_path="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path")" || return 1
  fi

  # Check if file_path is under artifact_dir (require exact prefix + /)
  # Without the trailing slash check, /path/to/artifacts-evil/goals.md
  # would falsely match /path/to/artifacts as a prefix.
  if [[ "$abs_file_path" != "$artifact_dir/"* ]]; then
    return 1
  fi

  # Strip artifact_dir prefix to get relative path
  local rel_path="${abs_file_path#"$artifact_dir/"}"

  # Map known artifacts to step names
  case "$rel_path" in
    "goals.md")
      echo "goals"
      return 0
      ;;
    "questions.md")
      echo "questions"
      return 0
      ;;
    "research/summary.md")
      echo "research"
      return 0
      ;;
    "design.md")
      echo "design"
      return 0
      ;;
    "structure.md")
      echo "structure"
      return 0
      ;;
    "plan.md")
      echo "plan"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# artifact_sync_state <file_path> <artifact_dir>
# Called after a known artifact is written:
# - Reads frontmatter status via frontmatter_get_status
# - If status: approved → update state.json artifacts map to set that step = "approved"
# - If status: draft → call pipeline_cascade_reset to reset that step and all downstream
# - For design.md specifically: also read wireframe_requested field and sync to state.json
artifact_sync_state() {
  local file_path="$1"
  local artifact_dir="$2"

  # Get the step name for this artifact
  local step
  step=$(artifact_is_known "$file_path" "$artifact_dir") || return 1

  # Read frontmatter status
  local fm_status
  fm_status=$(frontmatter_get_status "$file_path") || return 1

  # Read current state
  local state
  state=$(state_read) || return 1

  # Check if status actually changed before writing — avoids unnecessary
  # state writes and cascade resets on every artifact edit
  local current_status
  current_status=$(echo "$state" | jq -r ".artifacts.$step // \"draft\"")
  local state_changed=false

  if [[ "$fm_status" == "$current_status" ]]; then
    # Status unchanged — no state update needed
    :
  elif [[ "$fm_status" == "approved" ]]; then
    # Update that step to approved
    state=$(echo "$state" | jq -c ".artifacts.$step = \"approved\"")
    state_changed=true
  elif [[ "$fm_status" == "draft" ]]; then
    # Cascade reset from this step onwards
    pipeline_cascade_reset "$step" "$artifact_dir"
    state=$(state_read)
    state_changed=true
  fi

  # For design.md specifically: sync wireframe_requested field
  if [[ "$step" == "design" ]]; then
    # Read the design.md file and extract wireframe_requested from frontmatter
    # Look for "wireframe_requested: true" or "wireframe_requested: false"
    local wireframe_str_value="false"

    # Read first 10 lines to find wireframe_requested
    local line_num=0
    local in_frontmatter=0
    while IFS= read -r line && [[ $line_num -lt 10 ]]; do
      line_num=$((line_num + 1))

      # Line 1: must be opening ---
      if [[ $line_num -eq 1 ]]; then
        if [[ "$line" == "---" ]]; then
          in_frontmatter=1
        else
          break
        fi
        continue
      fi

      # Lines 2+: look for closing --- or wireframe_requested field
      if [[ $in_frontmatter -eq 1 ]]; then
        if [[ "$line" == "---" ]]; then
          break
        fi

        # Check for wireframe_requested field
        if [[ "$line" =~ ^wireframe_requested: ]]; then
          local value="${line#wireframe_requested:}"
          value="${value#"${value%%[![:space:]]*}"}"  # trim leading whitespace
          value="${value%"${value##*[![:space:]]}"}"  # trim trailing whitespace
          wireframe_str_value="$value"
        fi
      fi
    done < "$file_path"

    # Convert string to JSON boolean value
    local wireframe_json_value="false"
    if [[ "$wireframe_str_value" == "true" ]]; then
      wireframe_json_value="true"
    fi

    # Check if wireframe value actually changed
    local current_wireframe
    current_wireframe=$(echo "$state" | jq -r '.wireframe_requested // false')
    if [[ "$current_wireframe" != "$wireframe_json_value" ]]; then
      state=$(echo "$state" | jq -c ".wireframe_requested = $wireframe_json_value")
      state_changed=true
    fi
  fi

  # Only write state if something actually changed
  if [[ "$state_changed" == true ]]; then
    state_write_atomic "$state"
  fi
}
