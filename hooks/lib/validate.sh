#!/usr/bin/env bash
set -euo pipefail

# Source state.sh from the same directory (which transitively sources frontmatter.sh)
_validate_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_validate_script_dir/state.sh"

# validate_state_schema <artifact_dir>
# Checks and repairs .qrspi/state.json:
# - No state file → calls state_init_or_reconcile(), outputs "Created state.json from artifacts"
# - Missing version field (v0) → rebuilds via state_init_or_reconcile(), outputs "Migrated state.json from v0 to v1"
# - v1 with all fields → returns 0, no output
# - v1 missing wireframe_requested → adds it as false, outputs "Repaired: added wireframe_requested"
# - v1 missing active_task → adds it as null, outputs "Repaired: added active_task"
# - v1 missing artifacts map → rebuilds, outputs "Repaired: rebuilt artifacts from frontmatter"
# - Uses atomic write for all repairs
validate_state_schema() {
  local artifact_dir="$1"

  # Check if state file exists
  if [[ ! -f ".qrspi/state.json" ]]; then
    # No state file - create from artifacts
    state_init_or_reconcile "$artifact_dir"
    echo "Created state.json from artifacts"
    return 0
  fi

  # Read current state
  local json
  json=$(state_read)

  # Check for version field
  local has_version
  has_version=$(echo "$json" | jq 'has("version")' 2>/dev/null || echo "false")

  if [[ "$has_version" == "false" ]]; then
    # v0 migration - rebuild via state_init_or_reconcile
    state_init_or_reconcile "$artifact_dir"
    echo "Migrated state.json from v0 to v1"
    return 0
  fi

  # At this point we have version field, check for other required fields
  local needs_repair=false
  local repair_msgs=()

  # Check for wireframe_requested
  local has_wireframe
  has_wireframe=$(echo "$json" | jq 'has("wireframe_requested")' 2>/dev/null || echo "false")
  if [[ "$has_wireframe" == "false" ]]; then
    needs_repair=true
    repair_msgs+=("Repaired: added wireframe_requested")
    json=$(echo "$json" | jq -c '.wireframe_requested = false')
  fi

  # Check for active_task
  local has_active_task
  has_active_task=$(echo "$json" | jq 'has("active_task")' 2>/dev/null || echo "false")
  if [[ "$has_active_task" == "false" ]]; then
    needs_repair=true
    repair_msgs+=("Repaired: added active_task")
    json=$(echo "$json" | jq -c '.active_task = null')
  fi

  # Check for artifacts map
  local has_artifacts
  has_artifacts=$(echo "$json" | jq 'has("artifacts")' 2>/dev/null || echo "false")
  if [[ "$has_artifacts" == "false" ]]; then
    needs_repair=true
    repair_msgs+=("Repaired: rebuilt artifacts from frontmatter")

    # Rebuild artifacts from frontmatter
    local goals_status="draft"
    local questions_status="draft"
    local research_status="draft"
    local design_status="draft"
    local structure_status="draft"
    local plan_status="draft"
    local implement_status="draft"
    local test_status="draft"

    if [[ -f "$artifact_dir/goals.md" ]]; then
      goals_status=$(frontmatter_get_status "$artifact_dir/goals.md" || echo "draft")
    fi
    if [[ -f "$artifact_dir/questions.md" ]]; then
      questions_status=$(frontmatter_get_status "$artifact_dir/questions.md" || echo "draft")
    fi
    if [[ -f "$artifact_dir/research/summary.md" ]]; then
      research_status=$(frontmatter_get_status "$artifact_dir/research/summary.md" || echo "draft")
    fi
    if [[ -f "$artifact_dir/design.md" ]]; then
      design_status=$(frontmatter_get_status "$artifact_dir/design.md" || echo "draft")
    fi
    if [[ -f "$artifact_dir/structure.md" ]]; then
      structure_status=$(frontmatter_get_status "$artifact_dir/structure.md" || echo "draft")
    fi
    if [[ -f "$artifact_dir/plan.md" ]]; then
      plan_status=$(frontmatter_get_status "$artifact_dir/plan.md" || echo "draft")
    fi

    json=$(echo "$json" | jq -c \
      --arg goals "$goals_status" \
      --arg questions "$questions_status" \
      --arg research "$research_status" \
      --arg design "$design_status" \
      --arg structure "$structure_status" \
      --arg plan "$plan_status" \
      --arg implement "$implement_status" \
      --arg test "$test_status" \
      '.artifacts = {
        goals: $goals,
        questions: $questions,
        research: $research,
        design: $design,
        structure: $structure,
        plan: $plan,
        implement: $implement,
        test: $test
      }')
  fi

  # If repairs were made, write atomically and output messages
  if [[ "$needs_repair" == true ]]; then
    state_write_atomic "$json"
    for msg in "${repair_msgs[@]}"; do
      echo "$msg"
    done
  fi

  return 0
}

# validate_config <config_path>
# Checks config.md for required Phase 4 fields:
# - All fields present → returns 0, no output
# - Missing Phase 4 fields (enforcement_default) → adds defaults, outputs field names, returns 0
# - Config doesn't exist → returns 1
# - Preserves existing content when adding defaults
validate_config() {
  local config_path="$1"

  # Check if config exists
  if [[ ! -f "$config_path" ]]; then
    return 1
  fi

  # Read the file
  local content
  content=$(cat "$config_path")

  # Find the closing --- line (frontmatter must start with ---)
  local frontmatter_end=0
  local line_num=0
  local first_line_is_separator=false

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ $line_num -eq 1 ]]; then
      [[ "$line" == "---" ]] && first_line_is_separator=true
      continue
    fi
    if [[ "$first_line_is_separator" == true ]] && [[ "$line" == "---" ]]; then
      frontmatter_end=$line_num
      break
    fi
  done <<< "$content"

  # If no valid frontmatter, add it with defaults and re-read
  if [[ $frontmatter_end -eq 0 ]]; then
    local existing_content
    existing_content=$(cat "$config_path")
    printf -- '---\nenforcement_default: strict\n---\n%s' "$existing_content" > "$config_path"
    echo "config.md: added missing frontmatter with enforcement_default: strict"
    return 0
  fi

  # Extract frontmatter section (lines 2 through closing_line-1)
  local fm_section
  fm_section=$(sed -n '2,'$((frontmatter_end - 1))'p' "$config_path")

  # Check for enforcement_default field
  if ! echo "$fm_section" | grep -q "enforcement_default"; then
    # Need to add enforcement_default
    # Insert before the closing --- line
    local before_closing
    before_closing=$(head -n $((frontmatter_end - 1)) "$config_path")

    local after_closing
    after_closing=$(tail -n +$frontmatter_end "$config_path")

    # Reconstruct file
    local new_content="$before_closing
enforcement_default: strict
$after_closing"

    echo "$new_content" > "$config_path"
    echo "enforcement_default"
  fi

  return 0
}

# validate_task_specs <artifact_dir>
# Read-only scan of task specs:
# - All Phase 4 fields present → returns 0, no output
# - Missing enforcement/allowed_files/constraints → returns 0, outputs warnings
# - No task files → returns 0, no output
# - Never modifies task files
# - Always returns 0
validate_task_specs() {
  local artifact_dir="$1"

  # Find all task-NN.md files
  local task_files
  task_files=$(find "$artifact_dir/tasks" -maxdepth 1 -name "task-*.md" -type f 2>/dev/null | sort || true)

  # If no task files, return 0 with no output
  if [[ -z "$task_files" ]]; then
    return 0
  fi

  # Check each task file for required Phase 4 fields
  local warnings=()
  while IFS= read -r task_file; do
    [[ -z "$task_file" ]] && continue

    # Read the first 20 lines to extract frontmatter
    local frontmatter_section=""
    local line_num=0
    local in_frontmatter=false
    local found_closing=false

    while IFS= read -r line && [[ $line_num -lt 20 ]]; do
      line_num=$((line_num + 1))

      if [[ $line_num -eq 1 ]] && [[ "$line" == "---" ]]; then
        in_frontmatter=true
        continue
      fi

      if [[ "$in_frontmatter" == true ]]; then
        if [[ "$line" == "---" ]]; then
          found_closing=true
          break
        fi
        frontmatter_section+="$line"$'\n'
      fi
    done < "$task_file"

    # Skip if no valid frontmatter
    [[ "$found_closing" != true ]] && continue

    # Check for enforcement field
    if ! echo "$frontmatter_section" | grep -q "^enforcement:"; then
      warnings+=("$(basename "$task_file"): missing enforcement")
    fi

    # Check for allowed_files field
    if ! echo "$frontmatter_section" | grep -q "^allowed_files:"; then
      warnings+=("$(basename "$task_file"): missing allowed_files")
    fi

    # Check for constraints field
    if ! echo "$frontmatter_section" | grep -q "^constraints:"; then
      warnings+=("$(basename "$task_file"): missing constraints")
    fi
  done <<< "$task_files"

  # Output all warnings
  for warning in "${warnings[@]}"; do
    echo "$warning"
  done

  return 0
}
