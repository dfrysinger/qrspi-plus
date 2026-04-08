#!/usr/bin/env bash
set -euo pipefail

protected_is_blocked() {
  local target_path="$1"
  local is_worktree="$2"

  # Only block if IN a worktree (is_worktree=0 means worktree detected).
  # Worktree subagents must not modify pipeline infrastructure files
  # (task specs, state, audit logs). Main session can modify them freely.
  if [[ $is_worktree -ne 0 ]]; then
    return 1
  fi

  # Check protected patterns
  case "$target_path" in
    tasks/task-*.md)
      return 0
      ;;
    .qrspi/state.json)
      return 0
      ;;
    .qrspi/task-*-runtime.json)
      return 0
      ;;
    config.md)
      return 0
      ;;
    .qrspi/audit-task-*.jsonl)
      return 0
      ;;
    reviews/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
