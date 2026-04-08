#!/usr/bin/env bash
set -euo pipefail

# Source frontmatter.sh from the same directory
# Use a more robust method that works in all contexts
_state_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_state_script_dir/frontmatter.sh"

# state_init_or_reconcile <artifact_dir>
# Scans artifact files in the given directory, reads their frontmatter status,
# and creates/updates .qrspi/state.json in the current working directory.
state_init_or_reconcile() {
  local artifact_dir="$1"

  # Check if artifact_dir exists
  [[ -d "$artifact_dir" ]] || return 1

  # Determine statuses for all 8 artifacts
  local goals_status="draft"
  local questions_status="draft"
  local research_status="draft"
  local design_status="draft"
  local structure_status="draft"
  local plan_status="draft"
  local implement_status="draft"
  local test_status="draft"

  # Check goals.md
  if [[ -f "$artifact_dir/goals.md" ]]; then
    goals_status=$(frontmatter_get_status "$artifact_dir/goals.md" || echo "draft")
  fi

  # Check questions.md
  if [[ -f "$artifact_dir/questions.md" ]]; then
    questions_status=$(frontmatter_get_status "$artifact_dir/questions.md" || echo "draft")
  fi

  # Check research/summary.md
  if [[ -f "$artifact_dir/research/summary.md" ]]; then
    research_status=$(frontmatter_get_status "$artifact_dir/research/summary.md" || echo "draft")
  fi

  # Check design.md
  if [[ -f "$artifact_dir/design.md" ]]; then
    design_status=$(frontmatter_get_status "$artifact_dir/design.md" || echo "draft")
  fi

  # Check structure.md
  if [[ -f "$artifact_dir/structure.md" ]]; then
    structure_status=$(frontmatter_get_status "$artifact_dir/structure.md" || echo "draft")
  fi

  # Check plan.md
  if [[ -f "$artifact_dir/plan.md" ]]; then
    plan_status=$(frontmatter_get_status "$artifact_dir/plan.md" || echo "draft")
  fi

  # implement and test are never read from files, always draft unless inferred
  # (but for now we keep them as draft)

  # Determine current_step: first artifact that is NOT "approved"
  local current_step=""
  if [[ "$goals_status" != "approved" ]]; then
    current_step="goals"
  elif [[ "$questions_status" != "approved" ]]; then
    current_step="questions"
  elif [[ "$research_status" != "approved" ]]; then
    current_step="research"
  elif [[ "$design_status" != "approved" ]]; then
    current_step="design"
  elif [[ "$structure_status" != "approved" ]]; then
    current_step="structure"
  elif [[ "$plan_status" != "approved" ]]; then
    current_step="plan"
  elif [[ "$implement_status" != "approved" ]]; then
    current_step="implement"
  elif [[ "$test_status" != "approved" ]]; then
    current_step="test"
  else
    # All approved
    current_step="test"
  fi

  # Create absolute path for artifact_dir
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$artifact_dir" && pwd)"

  # Create the state JSON (compact format)
  local json
  json=$(jq -cn \
    --arg current_step "$current_step" \
    --arg artifact_dir "$abs_artifact_dir" \
    '{
      version: 1,
      current_step: $current_step,
      phase_start_commit: null,
      artifact_dir: $artifact_dir,
      wireframe_requested: false,
      artifacts: {
        goals: $goals,
        questions: $questions,
        research: $research,
        design: $design,
        structure: $structure,
        plan: $plan,
        implement: $implement,
        test: $test
      },
      active_task: null
    }' \
    --arg goals "$goals_status" \
    --arg questions "$questions_status" \
    --arg research "$research_status" \
    --arg design "$design_status" \
    --arg structure "$structure_status" \
    --arg plan "$plan_status" \
    --arg implement "$implement_status" \
    --arg test "$test_status")

  # Write the state file atomically
  state_write_atomic "$json"
}

# state_read
# Outputs .qrspi/state.json on stdout, returns 0.
# Returns 1 if file doesn't exist.
state_read() {
  local state_file=".qrspi/state.json"

  if [[ -f "$state_file" ]]; then
    cat "$state_file"
    return 0
  else
    return 1
  fi
}

# state_write_atomic <json_string>
# Writes JSON to .qrspi/state.json via temp file + mv for atomicity.
# Creates .qrspi/ directory if needed.
state_write_atomic() {
  local json="$1"

  # Create .qrspi directory if needed
  mkdir -p ".qrspi"

  # Create temp file in the same directory to ensure atomic rename
  local temp_file
  temp_file=$(mktemp ".qrspi/.state.json.XXXXXX")

  # Write JSON to temp file
  echo "$json" > "$temp_file"

  # Atomically move temp file to final location
  mv "$temp_file" ".qrspi/state.json"

  return 0
}
