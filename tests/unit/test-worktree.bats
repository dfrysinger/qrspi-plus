#!/usr/bin/env bats

setup() {
  source $BATS_TEST_DIRNAME/../../hooks/lib/worktree.sh
  source $BATS_TEST_DIRNAME/../../hooks/lib/protected.sh
}

# ===== worktree_is_inside tests =====

@test "worktree_is_inside: path inside worktree cwd returns 0" {
  run worktree_is_inside "/foo/bar" "/foo/bar/file.txt"
  [ "$status" -eq 0 ]
}

@test "worktree_is_inside: path outside worktree cwd returns non-zero" {
  run worktree_is_inside "/foo/bar" "/baz/file.txt"
  [ "$status" -ne 0 ]
}

@test "worktree_is_inside: prefix-but-different-dir returns non-zero" {
  run worktree_is_inside "/foo/bar" "/foo/barbaz/file"
  [ "$status" -ne 0 ]
}

# ===== worktree_detect tests =====

@test "worktree_detect: cwd with /.worktrees/ returns 0" {
  run worktree_detect "/home/user/.worktrees/task-01/src"
  [ "$status" -eq 0 ]
}

@test "worktree_detect: cwd without /.worktrees/ returns non-zero" {
  run worktree_detect "/home/user/project/src"
  [ "$status" -ne 0 ]
}

# ===== worktree_extract_task_id tests =====

@test "worktree_extract_task_id: extracts task-03 as 3" {
  run worktree_extract_task_id "/home/.worktrees/task-03/src/file.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "worktree_extract_task_id: extracts task-15 as 15" {
  run worktree_extract_task_id "/home/.worktrees/task-15/subdir/file.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "15" ]
}

@test "worktree_extract_task_id: extracts task ID from PWD without trailing slash" {
  run worktree_extract_task_id "/home/.worktrees/task-07"
  [ "$status" -eq 0 ]
  [ "$output" = "7" ]
}

@test "worktree_extract_task_id: non-worktree path returns error" {
  run worktree_extract_task_id "/home/user/project/file.sh"
  [ "$status" -ne 0 ]
}

# ===== protected_is_blocked tests =====

@test "protected_is_blocked: tasks/task-05.md in worktree is blocked" {
  run protected_is_blocked "tasks/task-05.md" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: .qrspi/state.json in worktree is blocked" {
  run protected_is_blocked ".qrspi/state.json" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: .qrspi/task-03-runtime.json in worktree is blocked" {
  run protected_is_blocked ".qrspi/task-03-runtime.json" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: config.md in worktree is blocked" {
  run protected_is_blocked "config.md" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: .qrspi/audit-task-03.jsonl in worktree is blocked" {
  run protected_is_blocked ".qrspi/audit-task-03.jsonl" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: reviews/alignment/report.md in worktree is blocked" {
  run protected_is_blocked "reviews/alignment/report.md" 0
  [ "$status" -eq 0 ]
}

@test "protected_is_blocked: hooks/lib/task.sh in worktree is not blocked" {
  run protected_is_blocked "hooks/lib/task.sh" 0
  [ "$status" -ne 0 ]
}

@test "protected_is_blocked: any path not in worktree is not blocked" {
  run protected_is_blocked "tasks/task-05.md" 1
  [ "$status" -ne 0 ]
}

# ===== Library structure tests =====

@test "worktree.sh uses set -euo pipefail" {
  grep -q "set -euo pipefail" $BATS_TEST_DIRNAME/../../hooks/lib/worktree.sh
}

@test "protected.sh uses set -euo pipefail" {
  grep -q "set -euo pipefail" $BATS_TEST_DIRNAME/../../hooks/lib/protected.sh
}

@test "worktree.sh does not source other libraries" {
  # Check that no 'source' or '. ' statements exist (excluding shebang and comments)
  ! grep -E "^\s*(source|\.)\s" $BATS_TEST_DIRNAME/../../hooks/lib/worktree.sh
}

@test "protected.sh does not source other libraries" {
  # Check that no 'source' or '. ' statements exist (excluding shebang and comments)
  ! grep -E "^\s*(source|\.)\s" $BATS_TEST_DIRNAME/../../hooks/lib/protected.sh
}
