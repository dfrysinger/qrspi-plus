#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "plan/SKILL.md documents the build_command field" {
  run grep -F 'build_command' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md allows 'none' as a build_command sentinel" {
  run grep -F "'none'" "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md runs build after tests in per-task verification" {
  run grep -E -i 'build.*after.*test|run.*build_command|run the (project|plan).*build' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md fails the task when build exits non-zero" {
  # Tighten: require the build-verification context so a stale doc that mentions
  # "non-zero exit" elsewhere (e.g., Codex error codes) doesn't satisfy this.
  # Uses flag-based awk (not range /pat/,/pat/) because start and end share "^###".
  run bash -c "awk '/^### Build Verification/{found=1} found && /^###/ && !/^### Build Verification/{exit} found' '$REPO_ROOT/skills/implement/SKILL.md' | grep -E -i 'non-zero exit fails the task|fail.*task.*build|non-zero.*exit.*captur'"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md states all-green rule" {
  run bash -c "awk '/^### Done Signal/,/^##[^#]/' '$REPO_ROOT/skills/implementer-protocol/SKILL.md' | grep -E -i 'four|tests.*build.*typecheck|all green|all (are )?required'"
  [ "$status" -eq 0 ]
}
