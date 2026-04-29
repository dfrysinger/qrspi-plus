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

  # Reject paths containing `..` segments outright. The
  # subagent-wall regex below is a substring match, so a crafted path like
  # `/tmp/.worktrees/x/task-1/../../../../etc/poison` would match the
  # `.worktrees/x/task-1/` substring and bypass containment even though shell
  # path-resolution lands outside the worktree. We reject any path with `..`
  # segments before regex match — defense-in-depth, no realpath dependency
  # (realpath also fails on non-existent paths, which the hook frequently
  # encounters for new-file Write targets).
  case "$path" in
    *"/../"*|*"/.."|"../"*|"..")
      return 1
      ;;
  esac

  if [[ $path =~ \.worktrees/([^/]+)/(task-[0-9]+|baseline)(/|$) ]]; then
    local slug="${BASH_REMATCH[1]}"
    # Defense in depth: slug itself must not contain `..` (the [^/]+ above
    # already excludes `/`, but a slug like `..evil` is suspicious).
    if [[ "$slug" == *".."* ]]; then
      return 1
    fi
    echo "$slug"
    return 0
  fi

  return 1
}
