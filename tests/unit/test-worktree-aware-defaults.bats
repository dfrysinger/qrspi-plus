#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
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
