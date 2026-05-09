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
  run grep -E -i 'non-zero.*exit.*fail|fail.*task.*build|build.*fail.*task' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md states all-green rule" {
  run grep -E -i 'tests green AND build green|all four checks|tests.*build.*typecheck.*lint' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}
