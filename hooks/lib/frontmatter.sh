#!/usr/bin/env bash
set -euo pipefail

# frontmatter_get <file_path> [field_name]
#
# Generic YAML frontmatter parser.
#
# Without field_name: parse all frontmatter fields and return a JSON object.
#   - Scalar fields (key: value) → JSON string
#   - Simple list fields (- item) → JSON array of strings
#   - Nested list fields (- key: val) → JSON array of objects
#
# With field_name: return only the value of the named field
#   (trimmed string for scalars, JSON array for lists).
#
# Exit codes:
#   0 — success (missing field returns empty string / [])
#   1 — file not found or not readable
#   2 — file has no frontmatter (no leading ---)
frontmatter_get() {
  local file="$1"
  local field_name="${2:-}"

  # Exit 1: file not found
  [[ -f "$file" ]] || return 1

  # Read lines from the file
  local lines=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done < "$file"

  # Exit 2: empty file or first line is not ---
  if [[ ${#lines[@]} -eq 0 ]]; then
    return 2
  fi
  if [[ "${lines[0]}" != "---" ]]; then
    return 2
  fi

  # Find the closing --- and extract frontmatter lines
  local fm_lines=()
  local found_closing=0
  local i=1
  while [[ $i -lt ${#lines[@]} ]]; do
    if [[ "${lines[$i]}" == "---" ]]; then
      found_closing=1
      break
    fi
    fm_lines+=("${lines[$i]}")
    i=$((i + 1))
  done

  # Exit 2: no closing ---
  if [[ $found_closing -eq 0 ]]; then
    return 2
  fi

  # Parse frontmatter lines into an associative structure.
  # We build JSON incrementally using jq.
  #
  # Strategy: walk lines, detect:
  #   1. "key: value" → scalar
  #   2. "key:" (no value, followed by "- ..." lines) → list
  #   3. "- item" under a list key → simple list item
  #   4. "- subkey: val" under a list key → nested object item
  #   5. "  subkey: val" continuation of nested object

  local json="{}"
  local current_key=""
  local current_list_json=""
  local current_obj_json=""
  local in_list=0
  local in_nested_obj=0

  _flush_obj() {
    if [[ $in_nested_obj -eq 1 && -n "$current_obj_json" ]]; then
      if [[ -z "$current_list_json" ]]; then
        current_list_json="[$current_obj_json]"
      else
        current_list_json="${current_list_json%]},${current_obj_json}]"
      fi
      current_obj_json=""
      in_nested_obj=0
    fi
  }

  _flush_list() {
    _flush_obj
    if [[ $in_list -eq 1 && -n "$current_key" ]]; then
      if [[ -z "$current_list_json" ]]; then
        current_list_json="[]"
      fi
      json=$(printf '%s' "$json" | jq --arg k "$current_key" --argjson v "$current_list_json" '.[$k] = $v')
      current_key=""
      current_list_json=""
      in_list=0
    fi
  }

  for fm_line in "${fm_lines[@]}"; do
    # Top-level key: value (no leading whitespace, has colon)
    if [[ "$fm_line" =~ ^([a-z_][a-z0-9_]*):(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local raw_val="${BASH_REMATCH[2]}"
      # Trim whitespace from value
      raw_val="${raw_val#"${raw_val%%[![:space:]]*}"}"
      raw_val="${raw_val%"${raw_val##*[![:space:]]}"}"

      if [[ -n "$raw_val" ]]; then
        # Scalar field — flush any pending list first
        _flush_list
        json=$(printf '%s' "$json" | jq --arg k "$key" --arg v "$raw_val" '.[$k] = $v')
      else
        # List field (key with no value) — flush previous list, start new
        _flush_list
        current_key="$key"
        current_list_json=""
        in_list=1
      fi

    # Simple list item: "- value" (exactly "- " at start)
    elif [[ $in_list -eq 1 && "$fm_line" =~ ^-\ (.+)$ ]]; then
      local item_val="${BASH_REMATCH[1]}"

      # Check if this is a nested key:value item like "- action: create"
      if [[ "$item_val" =~ ^([a-z_][a-z0-9_]*):\ (.+)$ ]]; then
        local sub_key="${BASH_REMATCH[1]}"
        local sub_val="${BASH_REMATCH[2]}"
        sub_val="${sub_val#"${sub_val%%[![:space:]]*}"}"
        sub_val="${sub_val%"${sub_val##*[![:space:]]}"}"
        # Flush any previous nested object
        _flush_obj
        in_nested_obj=1
        current_obj_json=$(jq -n --arg k "$sub_key" --arg v "$sub_val" '{($k): $v}')
      else
        # Simple list item
        _flush_obj
        item_val="${item_val#"${item_val%%[![:space:]]*}"}"
        item_val="${item_val%"${item_val##*[![:space:]]}"}"
        local item_json
        item_json=$(jq -n --arg v "$item_val" '$v')
        if [[ -z "$current_list_json" ]]; then
          current_list_json="[$item_json]"
        else
          current_list_json="${current_list_json%]},$item_json]"
        fi
      fi

    # Continuation of nested object: "  subkey: val"
    elif [[ $in_nested_obj -eq 1 && "$fm_line" =~ ^[[:space:]]+([a-z_][a-z0-9_]*):\ (.+)$ ]]; then
      local sub_key="${BASH_REMATCH[1]}"
      local sub_val="${BASH_REMATCH[2]}"
      sub_val="${sub_val#"${sub_val%%[![:space:]]*}"}"
      sub_val="${sub_val%"${sub_val##*[![:space:]]}"}"
      current_obj_json=$(printf '%s' "$current_obj_json" | jq --arg k "$sub_key" --arg v "$sub_val" '.[$k] = $v')
    fi
  done

  # Flush any remaining list/object
  _flush_list

  # Output
  if [[ -n "$field_name" ]]; then
    # Return specific field value
    local val
    val=$(printf '%s' "$json" | jq -r --arg k "$field_name" '.[$k] // empty')
    if [[ -n "$val" ]]; then
      # Check if it's a JSON array/object (starts with [ or {)
      local field_type
      field_type=$(printf '%s' "$json" | jq -r --arg k "$field_name" '.[$k] | type // empty')
      if [[ "$field_type" == "array" || "$field_type" == "object" ]]; then
        printf '%s' "$json" | jq -c --arg k "$field_name" '.[$k]'
      else
        echo "$val"
      fi
    fi
    return 0
  else
    # Return full JSON object
    printf '%s' "$json" | jq -c '.'
    return 0
  fi
}

# frontmatter_get_status <file>
# Compatibility wrapper — extracts the status field from frontmatter.
# Returns 0 with status value on stdout if found, 1 otherwise.
frontmatter_get_status() {
  local file="$1"
  local result
  local exit_code=0
  result=$(frontmatter_get "$file" "status") || exit_code=$?

  # Map exit code 2 (no frontmatter) to 1 for backward compatibility
  if [[ $exit_code -ne 0 ]]; then
    return 1
  fi

  # If status field was not found (empty result), return 1
  if [[ -z "$result" ]]; then
    return 1
  fi

  echo "$result"
  return 0
}
