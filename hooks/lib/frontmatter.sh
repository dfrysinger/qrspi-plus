#!/usr/bin/env bash
set -euo pipefail

# frontmatter_get_status <file>
# Extracts the status field from YAML frontmatter (first 5 lines only).
# Frontmatter must be properly delimited with --- on both sides.
# Returns 0 with status value on stdout if found, 1 otherwise.
frontmatter_get_status() {
  local file="$1"

  # Check if file exists
  [[ -f "$file" ]] || return 1

  # Read first 5 lines
  local line_num=0
  local in_frontmatter=0
  local found_closing=0
  local status_value=""

  while IFS= read -r line && [[ $line_num -lt 5 ]]; do
    line_num=$((line_num + 1))

    # Line 1: must be opening ---
    if [[ $line_num -eq 1 ]]; then
      if [[ "$line" == "---" ]]; then
        in_frontmatter=1
      else
        return 1
      fi
      continue
    fi

    # Lines 2-5: look for closing --- or status field
    if [[ $in_frontmatter -eq 1 ]]; then
      if [[ "$line" == "---" ]]; then
        found_closing=1
        break
      fi

      # Check for status field
      if [[ "$line" =~ ^status: ]]; then
        # Extract and trim the value
        local value="${line#status:}"
        value="${value#"${value%%[![:space:]]*}"}"  # trim leading whitespace
        value="${value%"${value##*[![:space:]]}"}"  # trim trailing whitespace
        status_value="$value"
      fi
    fi
  done < "$file"

  # Must have found closing --- and status value
  if [[ "$found_closing" -eq 1 && -n "$status_value" ]]; then
    echo "$status_value"
    return 0
  fi

  return 1
}
