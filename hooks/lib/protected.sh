#!/usr/bin/env bash
set -euo pipefail

# is_protected_path <target_path> <is_worktree>
#
# Legacy API (pre-T25): used by worktree-subagent enforcement to block writes
# to pipeline-infrastructure files. Returns 0 if blocked, 1 if allowed. The
# is_worktree gate (0=in-worktree, non-zero=outside) means main session bypasses.
#
# Kept for backward compat with test-worktree.bats. Prefer
# is_protected_qrspi_target() (T25) as the canonical check; it operates on
# fully-qualified target paths (relative or absolute) and is gate-agnostic so
# pre-tool-use can call it for both main chat and subagents.
is_protected_path() {
  local target_path="$1"
  local is_worktree="$2"

  # Only block if IN a worktree (is_worktree=0 means worktree detected).
  if [[ $is_worktree -ne 0 ]]; then
    return 1
  fi

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
    # Legacy pattern; canonical audit file is .qrspi/audit.jsonl. The wildcard
    # form is retained so existing callers with audit-task-* fixtures still
    # match; it does NOT correspond to a real file produced by audit.sh.
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

# is_protected_qrspi_target <target_path>
#
# Canonical T25 (R2 S-N1) hook-managed-write protection. Returns 0 if the path
# is a hook-managed file under any `.qrspi/` directory (repo-root or
# artifact-dir or any intermediate parent). Returns 1 otherwise.
#
# Hook-managed files (single source of truth):
#   - state.json           — written by state.sh only (state_write_atomic).
#   - audit.jsonl          — written by audit.sh only (audit_log_event).
#   - task-NN-runtime.json — written by implement orchestrator runtime helpers.
#   - audit-codex-review.jsonl — written by codex-companion-bg.sh.
#
# This protects all of:
#   - <repo>/.qrspi/state.json                                (R2 S-N1)
#   - <repo>/docs/qrspi/<slug>/.qrspi/state.json              (existing)
#   - <repo>/.qrspi/audit.jsonl
#   - <repo>/docs/qrspi/<slug>/.qrspi/audit.jsonl
#   - any path with `(^|/)\.qrspi/<protected-file>`
is_protected_qrspi_target() {
  local target="$1"
  if [[ "$target" =~ (^|/)\.qrspi/(state\.json|audit\.jsonl|audit-codex-review\.jsonl|task-[0-9]+-runtime\.json)$ ]]; then
    return 0
  fi
  return 1
}
