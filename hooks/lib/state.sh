#!/usr/bin/env bash
set -euo pipefail

# Source frontmatter.sh and artifact-map.sh from the same directory
# Use a more robust method that works in all contexts
_state_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_state_script_dir/frontmatter.sh"
source "$_state_script_dir/artifact-map.sh"

# state_compute_current_step <artifact_dir>
# Helper: scan artifact files in <artifact_dir>, determine the first pipeline step
# whose artifact frontmatter is not "approved", and echo that step name.
# Only the 8 file-backed steps (goals, questions, research, design, phasing,
# structure, plan, parallelize) are inspected. If all 8 are approved, echoes
# "implement" (the first non-file-backed step, which defaults to "draft"). This
# matches state_init_or_reconcile, where implement is the next step in pipeline
# order after parallelize-approved.
# Returns 1 if artifact_dir does not exist.
#
# Single source of truth for the "first non-approved step" computation.
# state_init_or_reconcile delegates here (FU-1 refactor 2026-04-28; T25 added
# parallelize as the 8th file-backed step).
state_compute_current_step() {
  local artifact_dir="$1"
  [[ -d "$artifact_dir" ]] || return 1

  local _step _artifact_file _status
  for _step in goals questions research design phasing structure plan parallelize; do
    _artifact_file="$artifact_dir/$(artifact_map_get "$_step")"
    _status="draft"
    if [[ -f "$_artifact_file" ]]; then
      if ! _status=$(frontmatter_get_status "$_artifact_file" 2>/dev/null); then
        _status="draft"
      fi
    fi
    if [[ "$_status" != "approved" ]]; then
      echo "$_step"
      return 0
    fi
  done

  # implement and test are never inferred from files; default to "implement" if
  # all 8 file-backed steps are approved (matches state_init_or_reconcile: the
  # next step after parallelize-approved is implement, since implement is also
  # "draft" by default and is the first non-approved step in pipeline order).
  echo "implement"
}

# state_init_or_reconcile <artifact_dir>
# Scans artifact files in the given directory, reads their frontmatter status,
# and creates/updates .qrspi/state.json in the current working directory.
state_init_or_reconcile() {
  local artifact_dir="$1"

  # Check if artifact_dir exists
  [[ -d "$artifact_dir" ]] || return 1

  # Determine statuses for all 10 artifacts (M54 added phasing between design and structure;
  # T25 R2 I-N4 added parallelize between plan and implement)
  local goals_status="draft"
  local questions_status="draft"
  local research_status="draft"
  local design_status="draft"
  local phasing_status="draft"
  local structure_status="draft"
  local plan_status="draft"
  local parallelize_status="draft"
  local implement_status="draft"
  local test_status="draft"

  # Check each artifact file using canonical mapping
  local _step _artifact_file
  for _step in goals questions research design phasing structure plan parallelize; do
    _artifact_file="$artifact_dir/$(artifact_map_get "$_step")"
    if [[ -f "$_artifact_file" ]]; then
      local _read_status
      if ! _read_status=$(frontmatter_get_status "$_artifact_file"); then
        echo "WARNING: cannot read status from $_artifact_file, defaulting to draft" >&2
        _read_status="draft"
      fi
      eval "${_step}_status=\$_read_status"
    fi
  done

  # implement and test are never read from files, always draft unless inferred
  # (but for now we keep them as draft)

  # Determine current_step: delegate to state_compute_current_step (FU-1
  # refactor 2026-04-28). state_compute_current_step is the single source of
  # truth for the "first non-approved step" computation, so any pipeline-order
  # change requires touching exactly one call site (the helper itself).
  local current_step
  if ! current_step=$(state_compute_current_step "$artifact_dir"); then
    echo "state_init_or_reconcile: state_compute_current_step failed" >&2
    return 1
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
        phasing: $phasing,
        structure: $structure,
        plan: $plan,
        parallelize: $parallelize,
        implement: $implement,
        test: $test
      }
    }' \
    --arg goals "$goals_status" \
    --arg questions "$questions_status" \
    --arg research "$research_status" \
    --arg design "$design_status" \
    --arg phasing "$phasing_status" \
    --arg structure "$structure_status" \
    --arg plan "$plan_status" \
    --arg parallelize "$parallelize_status" \
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
