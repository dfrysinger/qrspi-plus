#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance test for the asymmetric target-based enforcement model.
# Drives the pre-tool-use binary with synthetic envelopes against a fixture
# repo, asserting the spec Section 4.2 matrix.

setup() {
  export TEST_ROOT
  TEST_ROOT=$(mktemp -d)
  cd "$TEST_ROOT"

  mkdir -p "docs/qrspi/2026-04-26-fakeproj"
  mkdir -p ".worktrees/fakeproj/task-02/src"
  mkdir -p ".worktrees/fakeproj/task-03/src"
  mkdir -p "src"

  export HOOK="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/hooks/pre-tool-use"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# Helper: build an Edit envelope with optional agent_id
mk_edit() {
  local agent_id="$1"  # empty for main chat
  local target="$2"
  if [[ -n "$agent_id" ]]; then
    printf '{"agent_id":"%s","agent_type":"impl","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$agent_id" "$target"
  else
    printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$target"
  fi
}

# Helper: build a Bash envelope with optional agent_id
mk_bash() {
  local agent_id="$1"
  local cmd="$2"
  if [[ -n "$agent_id" ]]; then
    printf '{"agent_id":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$agent_id" "$cmd"
  else
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd"
  fi
}

# ── Subagent: writes inside its worktree → ALLOW ──────────────────
@test "subagent Edit inside its worktree → ALLOW" {
  local env=$(mk_edit "sub-1" "$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
}

# ── Subagent: writes to peer worktree → ALLOW (loose pinning) ─────
@test "subagent Edit in peer worktree → ALLOW (loose pinning)" {
  local env=$(mk_edit "sub-1" "$TEST_ROOT/.worktrees/fakeproj/task-03/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
}

# ── Subagent: writes outside any worktree → BLOCK ─────────────────
@test "subagent Edit outside any worktree → BLOCK" {
  local env=$(mk_edit "sub-1" "$TEST_ROOT/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
  [[ "$output" == *"outside worktree"* ]]
}

# ── Subagent: writes to artifact_dir .qrspi/ → BLOCK ──────────────
@test "subagent Edit to artifact_dir .qrspi/audit.jsonl → BLOCK" {
  local env=$(mk_edit "sub-1" "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

# ── Main chat: writes anywhere → ALLOW ────────────────────────────
@test "main chat Edit in random src → ALLOW" {
  local env=$(mk_edit "" "$TEST_ROOT/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
}

# ── Main chat: writes to artifact_dir .qrspi/ → BLOCK ─────────────
@test "main chat Edit to artifact_dir .qrspi/audit.jsonl → BLOCK" {
  local env=$(mk_edit "" "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

# ── Bash destructive: rm -rf * → BLOCK (everyone) ─────────────────
@test "subagent rm -rf * → BLOCK" {
  local env=$(mk_bash "sub-1" "rm -rf *")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

@test "main chat rm -rf * → BLOCK" {
  local env=$(mk_bash "" "rm -rf *")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

@test "subagent rm -rf ./build → ALLOW" {
  local env=$(mk_bash "sub-1" "rm -rf ./build")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
}

# ── Bash SQL: DROP DATABASE → BLOCK (everyone) ────────────────────
@test "subagent DROP DATABASE → BLOCK" {
  local env=$(mk_bash "sub-1" "psql -c \\\"DROP DATABASE app\\\"")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

@test "main chat DROP DATABASE → BLOCK" {
  local env=$(mk_bash "" "psql -c \\\"DROP DATABASE app\\\"")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

# ── Bash SQL: DROP TABLE → subagent BLOCK, main chat ALLOW ────────
@test "subagent DROP TABLE → BLOCK" {
  local env=$(mk_bash "sub-1" "psql -c \\\"DROP TABLE users\\\"")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

@test "main chat DROP TABLE → ALLOW" {
  local env=$(mk_bash "" "psql -c \\\"DROP TABLE users\\\"")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
}

# ── Bash SQL: TRUNCATE → subagent BLOCK ───────────────────────────
@test "subagent TRUNCATE → BLOCK" {
  local env=$(mk_bash "sub-1" "psql -c \\\"TRUNCATE foo\\\"")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 2 ]
}

# ── Audit assertions ──────────────────────────────────────────────
@test "ALLOW writes audit line to artifact_dir audit.jsonl" {
  local env=$(mk_edit "sub-1" "$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  grep -q '"outcome":"allow"' "$audit_file"
  grep -q '"agent_id":"sub-1"' "$audit_file"
}

@test "non-QRSPI write produces no audit log" {
  local env=$(mk_edit "" "$TEST_ROOT/src/foo.ts")
  run "$HOOK" <<< "$env"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl" ]
}
