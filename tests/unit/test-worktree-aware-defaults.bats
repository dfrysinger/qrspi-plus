#!/usr/bin/env bats
#
# Task 22 migration: REPO_ROOT resolution replaced by require_repo_root from
# the shared tests/helpers/skill-markdown.bash helper.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
}

@test "parallelize/SKILL.md mentions a worktree-aware setup-validation step" {
  run grep -E -i 'setup.validation|worktree.aware|\.worktrees' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md names the four config kinds checked" {
  run grep -F 'eslint' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F 'tsconfig' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -E 'vitest|jest' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md states validation is non-blocking (advisory)" {
  run bash -c "awk '/^### Worktree-Aware Setup Validation/{found=1} found && /^###/ && !/^### Worktree-Aware Setup Validation/{exit} found' \"\$REPO_ROOT/skills/parallelize/SKILL.md\" | grep -E -i 'does not block|not.*blocking|advisory|non.blocking'"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md mentions framework build dir like .next" {
  run grep -F '.next' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}
