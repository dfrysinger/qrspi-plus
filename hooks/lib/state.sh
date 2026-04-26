#!/usr/bin/env bash
set -euo pipefail

# Source frontmatter.sh and artifact-map.sh from the same directory
# Use a more robust method that works in all contexts
_state_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_state_script_dir/frontmatter.sh"
source "$_state_script_dir/artifact-map.sh"

# state_compute_current_step <state_json>
# Walks artifacts in pipeline order and returns the first non-approved step on
# stdout. If all eight are approved, returns "test" (the terminal step).
# Returns 0 on success, 1 if the state JSON is unparseable by jq.
#
# NOTE: implement and test never become "approved" via the file-frontmatter
# path (state_init_or_reconcile defaults them to draft; only out-of-band
# setters could approve them). So under current callers this loop will return
# "implement" once goals→plan are all approved, regardless of whether implement
# itself is approved. Future skills that mark implement/test approved must do
# so in state.json directly, after which this loop will advance correctly.
state_compute_current_step() {
  local state_json="$1"
  local step status
  for step in goals questions research design structure plan implement test; do
    if ! status=$(echo "$state_json" | jq -r ".artifacts.$step // \"draft\"" 2>/dev/null); then
      echo "state_compute_current_step: jq failed parsing state JSON for step '$step'" >&2
      return 1
    fi
    if [[ "$status" != "approved" ]]; then
      echo "$step"
      return 0
    fi
  done
  echo "test"
}

# state_init_or_reconcile <artifact_dir>
# Scans artifact files in the given directory, reads their frontmatter status,
# and creates/updates <artifact_dir>/.qrspi/state.json.
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

  # Check each artifact file using canonical mapping
  local _step _artifact_file
  for _step in goals questions research design structure plan; do
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

  # Create absolute path for artifact_dir
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$artifact_dir" && pwd)"

  # Build a provisional state JSON with current_step="" — we recompute it below
  # via state_compute_current_step so the logic lives in exactly one place.
  local json
  if ! json=$(jq -cn \
    --arg artifact_dir "$abs_artifact_dir" \
    '{
      version: 1,
      current_step: "",
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
      }
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

  # Compute current_step from artifact statuses and patch it in
  local current_step
  if ! current_step=$(state_compute_current_step "$json"); then
    echo "state_init_or_reconcile: state_compute_current_step failed" >&2
    return 1
  fi
  if ! json=$(echo "$json" | jq -c --arg cs "$current_step" '.current_step = $cs'); then
    echo "state_init_or_reconcile: jq patch of current_step failed" >&2
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

  # Write the state file atomically into the artifact_dir
  if ! state_write_atomic "$json" "$abs_artifact_dir"; then
    echo "state_init_or_reconcile: state_write_atomic failed" >&2
    return 1
  fi
}

# state_read [artifact_dir]
# Outputs <artifact_dir>/.qrspi/state.json on stdout.
# If artifact_dir is omitted, reads from .qrspi/state.json relative to PWD
# (legacy behavior — preserved for callers like the hooks that resolve the
# location target-based and pass it explicitly when known).
# Returns 1 if file doesn't exist.
state_read() {
  local artifact_dir="${1:-.}"
  local state_file="$artifact_dir/.qrspi/state.json"

  if [[ -f "$state_file" ]]; then
    cat "$state_file"
    return 0
  else
    return 1
  fi
}

# state_write_atomic <json_string> [artifact_dir]
# Writes JSON to <artifact_dir>/.qrspi/state.json via temp file + mv for atomicity.
# Creates <artifact_dir>/.qrspi/ directory if needed.
# If artifact_dir is omitted, writes to .qrspi/state.json relative to PWD
# (legacy behavior — preserved for callers that pre-cd into the artifact_dir).
state_write_atomic() {
  local json="$1"
  local artifact_dir="${2:-.}"
  local qrspi_dir="$artifact_dir/.qrspi"

  # Create .qrspi directory if needed
  if ! mkdir -p "$qrspi_dir" 2>/dev/null; then
    echo "state_write_atomic: failed to create $qrspi_dir directory" >&2
    return 1
  fi

  # Create temp file in the same directory to ensure atomic rename
  local temp_file
  if ! temp_file=$(mktemp "$qrspi_dir/.state.json.XXXXXX" 2>/dev/null); then
    echo "state_write_atomic: failed to create temp file in $qrspi_dir" >&2
    return 1
  fi

  # Write JSON to temp file
  if ! echo "$json" > "$temp_file" 2>/dev/null; then
    echo "state_write_atomic: failed to write to temp file $temp_file" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  # Atomically move temp file to final location
  if ! mv "$temp_file" "$qrspi_dir/state.json" 2>/dev/null; then
    echo "state_write_atomic: failed to move temp file to $qrspi_dir/state.json" >&2
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  return 0
}
