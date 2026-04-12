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
    if ! goals_status=$(frontmatter_get_status "$artifact_dir/goals.md"); then
      echo "WARNING: cannot read status from $artifact_dir/goals.md, defaulting to draft" >&2
      goals_status="draft"
    fi
  fi

  # Check questions.md
  if [[ -f "$artifact_dir/questions.md" ]]; then
    if ! questions_status=$(frontmatter_get_status "$artifact_dir/questions.md"); then
      echo "WARNING: cannot read status from $artifact_dir/questions.md, defaulting to draft" >&2
      questions_status="draft"
    fi
  fi

  # Check research/summary.md
  if [[ -f "$artifact_dir/research/summary.md" ]]; then
    if ! research_status=$(frontmatter_get_status "$artifact_dir/research/summary.md"); then
      echo "WARNING: cannot read status from $artifact_dir/research/summary.md, defaulting to draft" >&2
      research_status="draft"
    fi
  fi

  # Check design.md
  if [[ -f "$artifact_dir/design.md" ]]; then
    if ! design_status=$(frontmatter_get_status "$artifact_dir/design.md"); then
      echo "WARNING: cannot read status from $artifact_dir/design.md, defaulting to draft" >&2
      design_status="draft"
    fi
  fi

  # Check structure.md
  if [[ -f "$artifact_dir/structure.md" ]]; then
    if ! structure_status=$(frontmatter_get_status "$artifact_dir/structure.md"); then
      echo "WARNING: cannot read status from $artifact_dir/structure.md, defaulting to draft" >&2
      structure_status="draft"
    fi
  fi

  # Check plan.md
  if [[ -f "$artifact_dir/plan.md" ]]; then
    if ! plan_status=$(frontmatter_get_status "$artifact_dir/plan.md"); then
      echo "WARNING: cannot read status from $artifact_dir/plan.md, defaulting to draft" >&2
      plan_status="draft"
    fi
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
  if ! json=$(jq -cn \
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
    --arg test "$test_status"); then
    echo "state_init_or_reconcile: jq failed to build state JSON" >&2
    return 1
  fi

  if [[ -z "$json" ]]; then
    echo "state_init_or_reconcile: jq failed — empty output" >&2
    return 1
  fi

  # Validate output is well-formed JSON before writing (basic structural check)
  # Check starts with { and ends with }, and contains required "version" key
  local trimmed
  trimmed="${json#"${json%%[![:space:]]*}"}"
  if [[ "${trimmed:0:1}" != "{" ]] || [[ "${trimmed: -1}" != "}" ]]; then
    echo "state_init_or_reconcile: jq produced invalid JSON" >&2
    return 1
  fi
  if [[ "$json" != *'"version"'* ]]; then
    echo "state_init_or_reconcile: jq produced JSON missing required fields" >&2
    return 1
  fi

  # Write the state file atomically
  if ! state_write_atomic "$json"; then
    echo "state_init_or_reconcile: state_write_atomic failed" >&2
    return 1
  fi
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
  if ! mkdir -p ".qrspi" 2>/dev/null; then
    echo "state_write_atomic: failed to create .qrspi directory" >&2
    return 1
  fi

  # Create temp file in the same directory to ensure atomic rename
  local temp_file
  if ! temp_file=$(mktemp ".qrspi/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_write_atomic: failed to create temp file in .qrspi/" >&2
    return 1
  fi

  # Write JSON to temp file
  if ! echo "$json" > "$temp_file" 2>/dev/null; then
    echo "state_write_atomic: failed to write to temp file $temp_file" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  # Atomically move temp file to final location
  if ! mv "$temp_file" ".qrspi/state.json" 2>/dev/null; then
    echo "state_write_atomic: failed to move temp file to .qrspi/state.json" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  return 0
}
