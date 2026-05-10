#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "smoke-spec.md exists" {
  [ -f "$REPO_ROOT/skills/plan/smoke-spec.md" ]
}

@test "smoke-spec.md documents the smoke_checks: block name" {
  run grep -F 'smoke_checks:' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents required fields path, auth, expect_status" {
  run grep -F 'path' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'auth' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'expect_status' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents auth values none, signed-in, admin" {
  run grep -F 'none' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'signed-in' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'admin' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents optional fields including expect_body_contains and expect_link_href_pattern" {
  run grep -F 'expect_body_contains' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'expect_link_href_pattern' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md requires smoke_checks for route/page/layout/component tasks" {
  # smoke_checks did not exist in plan/SKILL.md before this task's edit, so the combined
  # pattern is unique: it cannot match pre-existing prose.
  run grep -E 'smoke_checks.*(route|page|layout|component)|(route|page|layout|component).*smoke_checks' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md declares the dev_command field with full prose (not just forward-reference stub)" {
  # The stub says 'reserved for the smoke-check gate'; the full prose says 'starts the dev server'.
  # This test fails on the stub and passes only after the replacement.
  run grep -E 'dev_command.*starts the dev server|starts the dev server.*dev_command' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md runs smoke checks after build" {
  # Use the specific script name 'run-smoke-checks.mjs' — more precise than 'smoke_checks' alone,
  # which could match the section heading added by this task.
  run grep -F 'run-smoke-checks.mjs' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}
