#!/usr/bin/env bash
set -euo pipefail

# Source the task library (which transitively sources frontmatter.sh)
source "$(dirname "${BASH_SOURCE[0]}")/task.sh"

# enforcement_get_mode <task_id> <artifact_dir>
# Determines the enforcement mode for a task.
# Checks runtime overrides first for mode override; falls back to task spec.
# If no Phase 4 fields present, returns "strict" (fail-closed).
# Outputs mode string on stdout.
enforcement_get_mode() {
  local task_id="$1"
  local artifact_dir="$2"

  # Check runtime overrides first (user mid-task decisions take precedence)
  local overrides_json
  if overrides_json=$(task_read_runtime_overrides "$task_id" 2>/dev/null); then
    local overrides_mode
    if overrides_mode=$(echo "$overrides_json" | jq -r '.enforcement // empty' 2>/dev/null); then
      if [[ -n "$overrides_mode" && "$overrides_mode" != "null" ]]; then
        # Validate mode value
        if [[ "$overrides_mode" != "strict" && "$overrides_mode" != "monitored" ]]; then
          echo "enforcement_get_mode: unrecognized mode '$overrides_mode' in runtime overrides for task $task_id" >&2
          return 1
        fi
        echo "$overrides_mode"
        return 0
      fi
    else
      echo "enforcement_get_mode: corrupted runtime overrides for task $task_id, falling through to spec" >&2
    fi
  fi

  # Fall back to task spec
  local spec_path
  spec_path=$(task_get_spec_path "$task_id" "$artifact_dir")

  if [[ ! -f "$spec_path" ]]; then
    echo "strict"
    return 0
  fi

  local frontmatter_json
  if ! frontmatter_json=$(frontmatter_get "$spec_path"); then
    echo "strict"
    return 0
  fi
  local mode
  mode=$(echo "$frontmatter_json" | jq -r '.enforcement // "strict"')

  # Validate mode
  if [[ "$mode" != "strict" && "$mode" != "monitored" ]]; then
    echo "enforcement_get_mode: unrecognized mode '$mode' for task $task_id" >&2
    return 1
  fi

  echo "$mode"
}

# enforcement_check_allowlist <file_path> <task_id> <artifact_dir>
# Checks if a file is allowed for the given task.
# Always evaluates the allowlist and outputs "true" or "false" on stdout to
# indicate whether the file is in scope. Enforcement mode controls whether
# an out-of-scope file blocks (strict) or is only logged (monitored).
#
# Exit codes:
#   0 - file is in scope (in_scope=true) — printed on stdout
#   0 - file is out of scope in monitored mode (in_scope=false, no block)
#   2 - file is out of scope in strict mode (in_scope=false, blocked)
#       also writes three-option message to stderr on exit 2
#   1 - error (cannot determine mode or read spec)
#
# Path matching: strips working directory prefix from file_path to get relative path.
enforcement_check_allowlist() {
  local file_path="$1"
  local task_id="$2"
  local artifact_dir="$3"

  # Get enforcement mode
  local mode
  if ! mode=$(enforcement_get_mode "$task_id" "$artifact_dir"); then
    echo "enforcement_check_allowlist: enforcement_get_mode failed for task $task_id" >&2
    return 1
  fi

  # Convert absolute path to relative so it matches allowlist entries.
  # Claude Code sends absolute paths (e.g., /Users/.../project/src/main.sh)
  # but task specs declare allowed files as relative (e.g., src/main.sh).
  # If the file is outside the working directory (e.g., /tmp/foo), the
  # absolute path is kept — it won't match any allowlist entry and will
  # be blocked.
  local rel_path="$file_path"
  local cwd
  cwd="$(pwd)"
  if [[ "$file_path" == /* ]]; then
    rel_path="${file_path#"${cwd}/"}"
    if [[ "$rel_path" == /* ]]; then
      rel_path="$file_path"
    fi
  fi

  # Read allowed_files from task spec
  local spec_path
  spec_path=$(task_get_spec_path "$task_id" "$artifact_dir")
  local frontmatter_json
  if ! frontmatter_json=$(frontmatter_get "$spec_path"); then
    echo "enforcement_check_allowlist: cannot read task spec frontmatter for task $task_id" >&2
    return 1
  fi
  local spec_allowed
  if ! spec_allowed=$(echo "$frontmatter_json" | jq -r '.allowed_files[]?.path // empty' 2>/dev/null); then
    echo "enforcement_check_allowlist: failed to parse allowed_files from spec — denying" >&2
    return 1
  fi

  # Check spec allowed_files
  while IFS= read -r allowed_path; do
    if [[ -n "$allowed_path" && "$allowed_path" == "$rel_path" ]]; then
      echo "true"
      return 0
    fi
  done <<< "$spec_allowed"

  # Check overrides user_approved_files
  local overrides_json
  if overrides_json=$(task_read_runtime_overrides "$task_id" 2>/dev/null); then
    local overrides_approved
    overrides_approved=$(echo "$overrides_json" | jq -r '.user_approved_files[]?' 2>/dev/null || true)
    while IFS= read -r approved_path; do
      if [[ -n "$approved_path" && "$approved_path" == "$rel_path" ]]; then
        echo "true"
        return 0
      fi
    done <<< "$overrides_approved"
  fi

  # File is not in either list — out of scope
  echo "false"

  # In monitored mode: log only, no block
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  # Strict mode: block with three-option message to stderr
  local padded_id
  padded_id=$(printf "%02d" "$task_id")
  printf "BLOCKED: File '%s' is not in the allowlist for task %s.\nOptions:\n  1. approve this file (add to runtime allowlist)\n  2. switch to monitored mode for this task\n  3. reject and stop\n" \
    "$rel_path" "$padded_id" >&2

  return 2
}
