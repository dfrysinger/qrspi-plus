#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "implementer-protocol/notifications.md exists" {
  [ -f "$REPO_ROOT/skills/implementer-protocol/notifications.md" ]
}

@test "notifications.md describes path tasks/task-NN/notifications/" {
  run grep -F 'tasks/task-' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
  run grep -F 'notifications/' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "notifications.md requires source task and changed file" {
  run grep -E -i 'source.*task|from.task' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
  run grep -E -i 'changed file|target file|file' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "notifications.md describes addressed/n-a marking" {
  run grep -E -i 'addressed|n/a|not applicable' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md links to notifications.md" {
  run grep -F 'notifications.md' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md has at-task-start step listing notifications/" {
  run grep -E -i 'notifications/|notifications directory|task start.*notifications' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md adds shared-base impact analysis step" {
  run grep -E -i 'shared.base impact|sibling.impact|sibling notification' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md references scripts/sibling-impact" {
  run grep -F 'sibling-impact' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "notifications.md specifies resolution recording via frontmatter" {
  # Resolution-recording section exists with a 'resolution' frontmatter
  # field that takes 'addressed' or 'n/a'.
  run awk '/^## Recording the resolution/{found=1} found && /^## /{print; if(seen){exit} seen=1; next} found' \
    "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
  awk '/^## Recording the resolution/{found=1} found && /^## / && !/^## Recording/{exit} found' \
    "$REPO_ROOT/skills/implementer-protocol/notifications.md" \
    | grep -E -i 'resolution: addressed|resolution: n/a|resolution.*addressed'
  [ "$?" -eq 0 ]
}

@test "implement/SKILL.md has round-level notification sweep section" {
  # The round-level sweep section must exist and tell the orchestrator
  # to dispatch a fix-cycle for tasks with unaddressed notifications,
  # even when they had no review findings.
  awk '/^### Round-Level Notification Sweep/{found=1} found && /^### / && !/^### Round-Level/{exit} found' \
    "$REPO_ROOT/skills/implement/SKILL.md" \
    | grep -E -i 'unaddressed|no review findings|even if'
  [ "$?" -eq 0 ]
  awk '/^### Round-Level Notification Sweep/{found=1} found && /^### / && !/^### Round-Level/{exit} found' \
    "$REPO_ROOT/skills/implement/SKILL.md" \
    | grep -E -i 'fix-cycle implementer|fix-cycle dispatch|dispatch.*implementer'
  [ "$?" -eq 0 ]
}
