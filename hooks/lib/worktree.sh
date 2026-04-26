#!/usr/bin/env bash
set -euo pipefail

worktree_is_inside() {
  local cwd="$1"
  local target_path="$2"

  # Append / to cwd to avoid prefix matching issues
  cwd="${cwd}/"

  [[ "$target_path" == "$cwd"* ]]
}

worktree_detect() {
  local cwd="$1"
  [[ "$cwd" == *"/.worktrees/"* ]]
}

worktree_extract_task_id() {
  local path="$1"

  if [[ $path =~ \.worktrees/task-([0-9]+)(/|$) ]]; then
    local task_num="${BASH_REMATCH[1]}"
    # Strip leading zeros
    echo "$((10#$task_num))"
    return 0
  fi

  return 1
}

worktree_extract_slug() {
  local path="$1"

  if [[ $path =~ \.worktrees/([^/]+)/(task-[0-9]+|baseline)(/|$) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}
