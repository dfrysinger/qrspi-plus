#!/usr/bin/env bash
set -euo pipefail

# Source state.sh (which transitively sources frontmatter.sh and artifact-map.sh)
_pipeline_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_pipeline_script_dir/state.sh"

# PIPELINE_ORDER — readonly array of 8 steps in order
# Use +a to disable readonly temporarily for proper array declaration, then re-enable
declare -a PIPELINE_ORDER=(goals questions research design structure plan implement test)
declare -r PIPELINE_ORDER

# _pipeline_get_step_index <step>
# Returns the index of the step in PIPELINE_ORDER (0-7), or -1 if not found
_pipeline_get_step_index() {
  local step="$1"
  case "$step" in
    goals) echo 0 ;;
    questions) echo 1 ;;
    research) echo 2 ;;
    design) echo 3 ;;
    structure) echo 4 ;;
    plan) echo 5 ;;
    implement) echo 6 ;;
    test) echo 7 ;;
    *) echo -1 ;;
  esac
}

# _pipeline_get_artifact_file <step> <artifact_dir>
# Returns the path to the artifact file for the given step, or empty string if no file
_pipeline_get_artifact_file() {
  local step="$1"
  local artifact_dir="$2"
  local rel_path
  if rel_path=$(artifact_map_get "$step" 2>/dev/null); then
    echo "$artifact_dir/$rel_path"
  else
    echo ""
  fi
}

# pipeline_check_prerequisites <step> <artifact_dir>
# Verifies all steps before the given step are approved.
# Does a dual check: reads state.json AND checks artifact frontmatter on disk.
# If state says approved but frontmatter says draft, trust frontmatter.
# Returns 0 if all prerequisites met.
# Returns 1 with the first missing prerequisite name on stdout if not met.
# Returns 1 for invalid step names.
# "goals" has no prerequisites → always returns 0.
pipeline_check_prerequisites() {
  local step="$1"
  local artifact_dir="$2"

  # Validate step
  local step_idx
  step_idx=$(_pipeline_get_step_index "$step")
  if [[ $step_idx -eq -1 ]]; then
    echo "<unknown-step>"
    echo "pipeline_check_prerequisites: unrecognized step '$step'" >&2
    return 1
  fi

  # "goals" has no prerequisites
  if [[ "$step" == "goals" ]]; then
    return 0
  fi

  # Read state.json from the artifact_dir
  local state
  if ! state=$(state_read "$artifact_dir" 2>/dev/null); then
    echo "<state-unavailable>"
    echo "pipeline_check_prerequisites: state_read failed for $artifact_dir" >&2
    return 1
  fi

  # Validate state is well-formed AND has the required shape. A bare {} or [] would
  # parse OK but then every state_status lookup defaults to "draft", producing a
  # misleading "Complete and approve goals" block reason instead of a corruption
  # signal. Require version + artifacts.{step} for at least one known step.
  if ! echo "$state" | jq -e 'type == "object" and has("version") and has("artifacts") and (.artifacts | type == "object")' >/dev/null 2>&1; then
    echo "<state-corrupted>"
    echo "pipeline_check_prerequisites: state.json at $artifact_dir/.qrspi/state.json is not valid JSON or missing required structure (version/artifacts) — Cannot verify pipeline ordering" >&2
    return 1
  fi

  # Check each prerequisite step (index 0 to step_idx-1)
  local i
  for (( i = 0; i < step_idx; i++ )); do
    # Get step name at index i
    local current_step
    case "$i" in
      0) current_step="goals" ;;
      1) current_step="questions" ;;
      2) current_step="research" ;;
      3) current_step="design" ;;
      4) current_step="structure" ;;
      5) current_step="plan" ;;
      6) current_step="implement" ;;
      7) current_step="test" ;;
      *) current_step="" ;;
    esac

    # Get status from state
    local state_status
    state_status=$(echo "$state" | jq -r ".artifacts.$current_step // \"draft\"")

    # Dual check: verify against frontmatter on disk
    local frontmatter_status="draft"

    # Get artifact file path
    local artifact_file
    artifact_file=$(_pipeline_get_artifact_file "$current_step" "$artifact_dir")

    # Read frontmatter status if file exists
    if [[ -n "$artifact_file" && -f "$artifact_file" ]]; then
      if fm_status=$(frontmatter_get_status "$artifact_file" 2>/dev/null); then
        frontmatter_status="$fm_status"
      fi
    fi

    # Trust frontmatter (source of truth)
    if [[ "$frontmatter_status" != "approved" ]]; then
      echo "$current_step"
      return 1
    fi
  done

  # All prerequisites met
  return 0
}

# pipeline_cascade_reset <step> <artifact_dir> [--skip-cascade]
# Resets the given step and all downstream steps to "draft" in state.json.
# With --skip-cascade: resets only the given step, leaves downstream untouched.
# Does NOT modify artifact files on disk.
# Uses state_write_atomic().
# If step is "goals", resets all 8 (unless --skip-cascade).
# If step is "test", resets only test.
# Rejects unknown flags with return 1.
pipeline_cascade_reset() {
  local step="$1"
  local artifact_dir="$2"
  shift 2

  # Parse optional flags
  local skip_cascade=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-cascade) skip_cascade=true; shift ;;
      *)
        echo "pipeline_cascade_reset: unknown flag '$1'" >&2
        return 1
        ;;
    esac
  done

  # Read current state from the artifact_dir
  local state
  if ! state=$(state_read "$artifact_dir" 2>/dev/null); then
    # No state file yet, create one
    if ! state_init_or_reconcile "$artifact_dir"; then
      echo "pipeline_cascade_reset: cannot perform cascade reset — state_init_or_reconcile failed" >&2
      return 1
    fi
    if ! state=$(state_read "$artifact_dir"); then
      echo "pipeline_cascade_reset: cannot perform cascade reset — state_read failed after init" >&2
      return 1
    fi
  fi

  # Find the index of the step
  local start_idx
  start_idx=$(_pipeline_get_step_index "$step")
  if [[ $start_idx -eq -1 ]]; then
    return 1
  fi

  # Determine end index
  local end_idx=8
  if [[ "$skip_cascade" == "true" ]]; then
    end_idx=$((start_idx + 1))
  fi

  # Reset from start_idx to end_idx to "draft"
  local i
  for (( i = start_idx; i < end_idx; i++ )); do
    local reset_step
    case "$i" in
      0) reset_step="goals" ;;
      1) reset_step="questions" ;;
      2) reset_step="research" ;;
      3) reset_step="design" ;;
      4) reset_step="structure" ;;
      5) reset_step="plan" ;;
      6) reset_step="implement" ;;
      7) reset_step="test" ;;
      *) reset_step="" ;;
    esac
    if ! state=$(echo "$state" | jq ".artifacts.$reset_step = \"draft\""); then
      echo "pipeline_cascade_reset: jq patch of artifacts.$reset_step failed" >&2
      return 1
    fi
  done

  # Recompute current_step after the cascade — F-7 invariant: any mutation of
  # artifacts.{step} must be followed by current_step recomputation. The
  # approval branch in artifact_sync_state already does this; the cascade/draft
  # path needs it too, otherwise reverting an approved artifact to draft leaves
  # current_step advanced too far.
  local new_current_step
  if ! new_current_step=$(state_compute_current_step "$state"); then
    echo "pipeline_cascade_reset: state_compute_current_step failed" >&2
    return 1
  fi
  if ! state=$(echo "$state" | jq -c --arg cs "$new_current_step" '.current_step = $cs'); then
    echo "pipeline_cascade_reset: jq patch of current_step failed" >&2
    return 1
  fi

  # Write atomically into the artifact_dir
  if ! state_write_atomic "$state" "$artifact_dir"; then
    echo "pipeline_cascade_reset: cannot perform cascade reset — state_write_atomic failed" >&2
    return 1
  fi
}
