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
    overrides_mode=$(echo "$overrides_json" | jq -r '.enforcement // empty' 2>/dev/null || true)
    if [[ -n "$overrides_mode" && "$overrides_mode" != "null" ]]; then
      echo "$overrides_mode"
      return 0
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
  frontmatter_json=$(frontmatter_get "$spec_path")
  local mode
  mode=$(echo "$frontmatter_json" | jq -r '.enforcement // "strict"')

  echo "$mode"
}

# enforcement_check_allowlist <file_path> <task_id> <artifact_dir>
# Checks if a file is allowed for the given task.
# In monitored mode: always returns 0.
# In strict mode: returns 0 if file is in allowed_files or overrides user_approved_files,
#                 returns 2 if not (also writes three-option message to stderr).
# Path matching: strips working directory prefix from file_path to get relative path.
enforcement_check_allowlist() {
  local file_path="$1"
  local task_id="$2"
  local artifact_dir="$3"

  # Get enforcement mode
  local mode
  mode=$(enforcement_get_mode "$task_id" "$artifact_dir")

  # Validate mode — unrecognized values fail closed
  if [[ "$mode" != "strict" && "$mode" != "monitored" ]]; then
    echo "enforcement_check_allowlist: unrecognized mode '$mode' for task $task_id — defaulting to strict" >&2
    mode="strict"
  fi

  # Monitored mode: always allow
  if [[ "$mode" != "strict" ]]; then
    return 0
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
  frontmatter_json=$(frontmatter_get "$spec_path")
  local spec_allowed
  spec_allowed=$(echo "$frontmatter_json" | jq -r '.allowed_files[].path' 2>/dev/null || true)

  # Check spec allowed_files
  while IFS= read -r allowed_path; do
    if [[ -n "$allowed_path" && "$allowed_path" == "$rel_path" ]]; then
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
        return 0
      fi
    done <<< "$overrides_approved"
  fi

  # File is not in either list — blocked
  local padded_id
  padded_id=$(printf "%02d" "$task_id")
  printf "BLOCKED: File '%s' is not in the allowlist for task %s.\nOptions:\n  1. approve this file (add to runtime allowlist)\n  2. switch to monitored mode for this task\n  3. reject and stop\n" \
    "$rel_path" "$padded_id" >&2

  return 2
}
