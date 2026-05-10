#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

setup() {
  # Each test runs in its own throwaway git repo with a tasks/ tree.
  TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR"
  git init -q
  git config user.email t@t.test
  git config user.name t
  git checkout -q -b base

  mkdir -p src/lib tasks/task-01 tasks/task-02 tasks/task-03
  echo 'export type X = { a: number };' > src/lib/types.ts
  echo "Task 01 — modifies src/lib/types.ts" > tasks/task-01/spec.md
  echo "Task 02 — references src/lib/types.ts" > tasks/task-02/spec.md
  echo "Task 03 — does not touch types.ts" > tasks/task-03/spec.md

  git add .
  git commit -q -m "base"

  # Task 01 modifies the shared type.
  git checkout -q -b task-01
  echo 'export type X = { kind: "a"; a: number } | { kind: "b" };' > src/lib/types.ts
  git add .
  git commit -q -m "task-01: change X"
  TASK_01_SHA="$(git rev-parse HEAD)"

  export TMP_DIR TASK_01_SHA
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

@test "writes a notification for sibling task that references the changed file" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  # task-02 references types.ts → notification expected.
  run bash -c "ls $TMP_DIR/tasks/task-02/notifications/*.md 2>/dev/null | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]

  # task-03 does not reference types.ts → no notification.
  [ ! -d "$TMP_DIR/tasks/task-03/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-03/notifications | wc -l)" -eq 0 ]

  # task-01 (the source) does not get a self-notification.
  [ ! -d "$TMP_DIR/tasks/task-01/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-01/notifications | wc -l)" -eq 0 ]
}

@test "notification names source task and changed file" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  notif="$(ls $TMP_DIR/tasks/task-02/notifications/*.md | head -1)"
  run grep -F 'source_task: 01' "$notif"
  [ "$status" -eq 0 ]
  run grep -F 'src/lib/types.ts' "$notif"
  [ "$status" -eq 0 ]
}

@test "exits 0 when no siblings reference the changed file" {
  # Make a change in a file no sibling references.
  cd "$TMP_DIR"
  git checkout -q task-01
  echo 'orphan' > src/lib/orphan-no-refs.ts
  git add .
  git commit -q -m "orphan add"
  ORPHAN_SHA="$(git rev-parse HEAD)"

  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$ORPHAN_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]
}

@test "exits 1 when --task-id is missing" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "task-id" ]]
}

@test "exits 1 when --commit is missing" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "commit" ]]
}

@test "skips changes inside the source task's own directory" {
  cd "$TMP_DIR"
  git checkout -q task-01
  echo 'self change' >> tasks/task-01/spec.md
  git add .
  git commit -q -m "task-01 self change"
  SELF_SHA="$(git rev-parse HEAD)"

  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$SELF_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  # No sibling notifications.
  [ ! -d "$TMP_DIR/tasks/task-02/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-02/notifications | wc -l)" -eq 0 ]
}

@test "--code-path overrides tasksDir/.. derivation for split-workspace layouts" {
  # Simulate a split-workspace: artifacts in one tree (no git), code in a separate tree (with git).
  ARTIFACTS_DIR="$(mktemp -d)"
  mkdir -p "$ARTIFACTS_DIR/tasks/task-01" "$ARTIFACTS_DIR/tasks/task-02" "$ARTIFACTS_DIR/tasks/task-03"
  echo "Task 01 — modifies src/lib/types.ts" > "$ARTIFACTS_DIR/tasks/task-01/spec.md"
  echo "Task 02 — references src/lib/types.ts" > "$ARTIFACTS_DIR/tasks/task-02/spec.md"
  echo "Task 03 — does not touch types.ts" > "$ARTIFACTS_DIR/tasks/task-03/spec.md"

  # Source tasks/task-01/notifications-permission probe is unrelated; the parent
  # dir of $ARTIFACTS_DIR/tasks is intentionally NOT a git repo. Without
  # --code-path, the script would try to run `git diff` from $ARTIFACTS_DIR
  # (the derived projectRoot) and fail. With --code-path pointing at $TMP_DIR
  # (the git repo from setup), it should succeed.

  run node "$REPO_ROOT/scripts/sibling-impact.mjs" \
    --task-id 01 --commit "$TASK_01_SHA" --base base \
    --tasks-dir "$ARTIFACTS_DIR/tasks" \
    --code-path "$TMP_DIR"
  [ "$status" -eq 0 ]

  # task-02 references types.ts → notification expected at the artifact tree.
  run bash -c "ls $ARTIFACTS_DIR/tasks/task-02/notifications/*.md 2>/dev/null | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]

  rm -rf "$ARTIFACTS_DIR"
}

@test "--code-path errors clearly when path does not exist" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" \
    --task-id 01 --commit "$TASK_01_SHA" --base base \
    --tasks-dir "$TMP_DIR/tasks" \
    --code-path "/nonexistent-code-path-for-sibling-impact-test"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "code-path not found" ]]
}
