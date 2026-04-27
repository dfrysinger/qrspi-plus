#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  export TEST_ROOT
  TEST_ROOT=$(mktemp -d)
  cd "$TEST_ROOT"

  # Fake repo layout: artifact dir + worktree
  mkdir -p "docs/qrspi/2026-04-26-fakeproj"
  mkdir -p ".worktrees/fakeproj/task-02/src"
  mkdir -p ".worktrees/fakeproj/baseline"

  source "$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/hooks/lib/worktree.sh"
  source "$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/hooks/lib/audit.sh"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── audit_resolve_artifact_dir ────────────────────────────────────

@test "resolve: single matching slug → returns absolute path" {
  result=$(audit_resolve_artifact_dir "fakeproj")
  [[ "$result" == *"docs/qrspi/2026-04-26-fakeproj" ]]
}

@test "resolve: zero matches → returns nonzero" {
  run audit_resolve_artifact_dir "no-such-slug"
  [ "$status" -ne 0 ]
}

@test "resolve: multiple matches → returns nonzero" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run audit_resolve_artifact_dir "fakeproj"
  [ "$status" -ne 0 ]
}

@test "[Important #1] resolve: zero matches → silent (no stderr)" {
  run --separate-stderr audit_resolve_artifact_dir "no-such-slug"
  [ "$status" -ne 0 ]
  [ -z "$stderr" ]
}

@test "[Important #1] resolve: ambiguous slug → fail-loud diagnostic on stderr" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run --separate-stderr audit_resolve_artifact_dir "fakeproj"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"ambiguous"* ]]
  [[ "$stderr" == *"fakeproj"* ]]
}

@test "[Important #1] resolve: ambiguous slug stderr names both directories" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run --separate-stderr audit_resolve_artifact_dir "fakeproj"
  [[ "$stderr" == *"2026-04-26-fakeproj"* ]]
  [[ "$stderr" == *"2026-05-01-fakeproj"* ]]
}

@test "[Important #1+3] integration: diagnostic propagates through audit_log_event call chain" {
  # Proves Item C delivers on its premise: when audit_resolve_artifact_dir
  # writes a diagnostic, audit_log_event must NOT swallow it. Otherwise the
  # 2>/dev/null drop in pre-tool-use's block()/allow() is theater.
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run --separate-stderr audit_log_event "$envelope" "allow" ""
  [[ "$stderr" == *"ambiguous"* ]]
  [[ "$stderr" == *"fakeproj"* ]]
}

# ── audit_log_event ───────────────────────────────────────────────

@test "[F-19] log: subagent Edit inside task-07a worktree audits to artifact_dir" {
  # Pins the cross-file regex invariant: pre-tool-use accepts task-07a, AND
  # worktree_extract_slug must too — otherwise audit silently drops the row
  # (Codex round-2 finding; was missed by both Claude reviewers).
  mkdir -p "$TEST_ROOT/.worktrees/fakeproj/task-07a/src"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-07a/src/foo.ts"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  [[ "$(cat "$audit_file")" == *"task-07a"* ]]
}

@test "[F-19] log: subagent Bash detected write under task-07b audits to artifact_dir" {
  mkdir -p "$TEST_ROOT/.worktrees/fakeproj/task-07b"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-07b/build.log"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Bash","tool_input":{"command":"echo done > '"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  [[ "$(cat "$audit_file")" == *"task-07b"* ]]
}

@test "log: subagent Edit inside worktree writes line to artifact_dir audit.jsonl" {
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]

  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"tool\":\"Edit\""* ]]
  [[ "$line" == *"\"outcome\":\"allow\""* ]]
  [[ "$line" == *"\"agent_id\":\"sub-1\""* ]]
  [[ "$line" == *"\"target\":\"$target\""* ]]
}

@test "log: main chat Edit on artifact_dir file writes audit line" {
  local target="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/goals.md"
  local envelope='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
}

@test "log: target outside QRSPI scope → no audit, return 0" {
  local target="$TEST_ROOT/some/random/file.ts"
  mkdir -p "$TEST_ROOT/some/random"
  local envelope='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  # No audit file created anywhere
  [ ! -f "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl" ]
}

@test "log: block outcome includes reason field" {
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/.qrspi/audit.jsonl"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "block" "subagent cannot write artifact .qrspi"
  [ "$status" -eq 0 ]

  # Block was attempting to write a (non-QRSPI) target — but path string contains
  # ".worktrees/fakeproj/" so the slug resolves and the artifact_dir gets the line.
  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"outcome\":\"block\""* ]]
  [[ "$line" == *"\"reason\":\"subagent cannot write artifact .qrspi\""* ]]
}

@test "log: Bash with detected write target inside worktree audits" {
  local envelope='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"echo hi > '"$TEST_ROOT"'/.worktrees/fakeproj/task-02/foo.txt"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"tool\":\"Bash\""* ]]
  [[ "$line" == *"\"command\":"* ]]
}

@test "log: Bash with no parseable target → no audit" {
  local envelope='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"ls -la"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl" ]
}

# ── Structural meta-tests ─────────────────────────────────────────

@test "audit.sh uses set -euo pipefail" {
  grep -q "set -euo pipefail" "$BATS_TEST_DIRNAME/../../hooks/lib/audit.sh"
}

@test "audit.sh sources exactly worktree.sh and bash-detect.sh (intentional exception)" {
  # Other libs are self-contained per the structural rule. audit.sh is the
  # documented exception because it needs slug extraction and bash write detection.
  local sources
  sources=$(grep -E "^\s*source\s" "$BATS_TEST_DIRNAME/../../hooks/lib/audit.sh" | sed 's/.*\///' | sed 's/".*//' | sort)
  [ "$sources" = "$(printf 'bash-detect.sh\nworktree.sh')" ]
}
