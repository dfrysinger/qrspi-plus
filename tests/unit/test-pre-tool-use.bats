#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Setup: create temp artifact dir and temp working dir with .qrspi/state.json
setup() {
  export ARTIFACT_DIR
  ARTIFACT_DIR=$(mktemp -d)
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  # Create artifact files directory structure
  mkdir -p "$ARTIFACT_DIR/research"

  # Path to the hook under test
  export HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
}

teardown() {
  rm -rf "$ARTIFACT_DIR" "$WORK_DIR"
}

# Helper: create an artifact with given status
create_artifact() {
  local path="$1"
  local status="$2"
  mkdir -p "$(dirname "$path")"
  printf -- '---\nstatus: %s\n---\nContent\n' "$status" > "$path"
}

# Helper: init state.json by sourcing pipeline lib and calling state_init_or_reconcile
init_state() {
  local artifact_dir="$1"
  # Source pipeline lib which sources state.sh which sources frontmatter.sh
  PIPELINE_LIB="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
  bash -c "source '$PIPELINE_LIB'; cd '$WORK_DIR'; state_init_or_reconcile '$artifact_dir'"
}

# ──────────────────────────────────────────────────────────────
# Test 1: Write to design.md with goals+questions+research approved → exit 0
# ──────────────────────────────────────────────────────────────
@test "Write to design.md with goals+questions+research approved allows (exit 0)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"new content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 2: Write to design.md with goals draft → exit 2 with "goals" in reason
# ──────────────────────────────────────────────────────────────
@test "Write to design.md with goals draft blocks (exit 2) with goals in reason" {
  create_artifact "$ARTIFACT_DIR/goals.md" "draft"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"new content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# ──────────────────────────────────────────────────────────────
# Test 3: Edit to structure.md with design not approved → exit 2
# ──────────────────────────────────────────────────────────────
@test "Edit to structure.md with design not approved blocks (exit 2)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Edit","tool_input":{"file_path":"'"$ARTIFACT_DIR/structure.md"'","old_string":"old","new_string":"new"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"design"* ]]
}

# ──────────────────────────────────────────────────────────────
# Test 4: Write to non-artifact (hooks/lib/foo.sh) → exit 0
# ──────────────────────────────────────────────────────────────
@test "Write to non-artifact file allows (exit 0)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"/some/project/hooks/lib/foo.sh","content":"#!/bin/bash"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 5: Bash tool call → exit 0
# ──────────────────────────────────────────────────────────────
@test "Bash tool call allows (exit 0)" {
  local json
  json='{"tool_name":"Bash","tool_input":{"command":"echo hello"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 6: Malformed JSON → exit 2 (fail-closed)
# ──────────────────────────────────────────────────────────────
@test "Malformed JSON blocks (exit 2, fail-closed)" {
  run "$HOOK" <<< "this is not json at all"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# Test 7: No state file → exit 0 for artifact writes (no pipeline to enforce yet)
# ──────────────────────────────────────────────────────────────
@test "No state file allows artifact write (no pipeline to enforce yet)" {
  # WORK_DIR has no .qrspi/state.json — no pipeline state means no ordering
  # to enforce. Avoids deadlock where first artifact can never be written.

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 8: stderr message includes next-step instructions on block
# ──────────────────────────────────────────────────────────────
@test "Blocked write emits informative stderr message" {
  create_artifact "$ARTIFACT_DIR/goals.md" "draft"
  create_artifact "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md" "draft"
  create_artifact "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/design.md"'","content":"content"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  # stderr (captured in $output when using run without --separate-stderr, but bats merges them)
  # Check that the block JSON reason is meaningful
  [[ "$output" == *"goals"* ]]
  [[ "$output" == *"design"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U1] Unknown tool "Memoize" → exit 0, stdout {}, stderr WARNING
# ──────────────────────────────────────────────────────────────
@test "[T03-U1] Unknown tool name emits warning to stderr and exits 0" {
  local json='{"tool_name":"Memoize","tool_input":{}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"unknown tool_name"* ]]
  [[ "$stderr" == *"Memoize"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U2] Write to goals.md with no state file → exit 0, stderr WARNING
# ──────────────────────────────────────────────────────────────
@test "[T03-U2] Write to goals.md with no state file emits warning and exits 0" {
  # WORK_DIR has no .qrspi/state.json
  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/goals.md"'","content":"x"}}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
  [[ "$stderr" == *"WARNING"* ]]
  [[ "$stderr" == *"no state file"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T03-U6] Bash tool_input not an object → exit 2, deny JSON
# ──────────────────────────────────────────────────────────────
@test "[T03-U6] Bash tool_input not an object blocks with deny JSON" {
  local json='{"tool_name":"Bash","tool_input":"not-an-object"}'

  run --separate-stderr "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$stderr" == *"BLOCKED"* ]]
  [[ "$stderr" == *"Cannot parse Bash command"* ]]
  local decision
  decision=$(printf '%s' "$output" | jq -r '.decision')
  [[ "$decision" == "block" ]]
}

# ──────────────────────────────────────────────────────────────
# [runtime] subagent Edit inside worktree allows
# ──────────────────────────────────────────────────────────────
@test "[runtime] subagent Edit inside worktree allows" {
  mkdir -p "$WORK_DIR/.worktrees/myslug/task-01/src"
  mkdir -p "$WORK_DIR/docs/qrspi/2026-04-26-myslug"

  local target="$WORK_DIR/.worktrees/myslug/task-01/src/foo.ts"
  local json='{"agent_id":"sub-1","agent_type":"impl","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] subagent Edit outside worktree blocks
# ──────────────────────────────────────────────────────────────
@test "[runtime] subagent Edit outside worktree blocks" {
  local target="$WORK_DIR/random/foo.ts"
  mkdir -p "$WORK_DIR/random"
  local json='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] main chat Edit anywhere allows
# ──────────────────────────────────────────────────────────────
@test "[runtime] main chat Edit anywhere allows" {
  local target="$WORK_DIR/random/foo.ts"
  mkdir -p "$WORK_DIR/random"
  local json='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] anyone running rm -rf * blocks
# ──────────────────────────────────────────────────────────────
@test "[runtime] anyone running rm -rf * blocks" {
  local json='{"tool_name":"Bash","tool_input":{"command":"rm -rf *"}}'
  cd "$WORK_DIR"
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [runtime] empty artifact_dir in state.json blocks (fail-closed)
# ──────────────────────────────────────────────────────────────
@test "[runtime] empty artifact_dir in state.json blocks pipeline-ordered write" {
  cd "$WORK_DIR"
  mkdir -p .qrspi
  printf '{"artifact_dir":"","current_step":"goals"}' > .qrspi/state.json
  mkdir -p docs/qrspi/2026-04-26-myslug
  local target="$WORK_DIR/docs/qrspi/2026-04-26-myslug/design.md"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"artifact_dir missing"* ]]
}

# ──────────────────────────────────────────────────────────────
# [runtime] .qrspi/ protection regex anchors to path segment
# ──────────────────────────────────────────────────────────────
@test "[runtime] .qrspi/ protection regex anchors to path segment (no false match on substring)" {
  cd "$WORK_DIR"
  mkdir -p notdocs/qrspi/foo/.qrspi
  local target="$WORK_DIR/notdocs/qrspi/foo/.qrspi/bar.txt"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N1-A] Repo-root .qrspi/state.json write from main chat is blocked
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N1-A] main chat Write to .qrspi/state.json blocks (repo-root protection)" {
  cd "$WORK_DIR"
  local target="$WORK_DIR/.qrspi/state.json"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"{}"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N1-B] Repo-root .qrspi/audit.jsonl write from main chat is blocked
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N1-B] main chat Write to .qrspi/audit.jsonl blocks (repo-root protection)" {
  cd "$WORK_DIR"
  local target="$WORK_DIR/.qrspi/audit.jsonl"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"{}"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N1-C] Repo-root .qrspi/task-NN-runtime.json write from main chat is blocked
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N1-C] main chat Write to .qrspi/task-03-runtime.json blocks" {
  cd "$WORK_DIR"
  local target="$WORK_DIR/.qrspi/task-03-runtime.json"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"{}"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N1-D] Existing artifact-dir .qrspi/ protection still works
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N1-D] artifact-dir .qrspi/state.json write still blocks (regression)" {
  cd "$WORK_DIR"
  mkdir -p docs/qrspi/2026-04-26-myslug/.qrspi
  local target="$WORK_DIR/docs/qrspi/2026-04-26-myslug/.qrspi/state.json"
  local json='{"tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"{}"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N1-E] Repo-root .qrspi/ protection also fires for Bash redirects
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N1-E] Bash redirect to .qrspi/state.json is blocked (main chat)" {
  cd "$WORK_DIR"
  local cmd="echo {} > $WORK_DIR/.qrspi/state.json"
  local json='{"tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-I-N4-A] parallelization.md write before plan.md approved blocks
# ──────────────────────────────────────────────────────────────
@test "[T25-I-N4-A] Write to parallelization.md with plan draft blocks (exit 2) with plan in reason" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "approved"
  create_artifact "$ARTIFACT_DIR/phasing.md" "approved"
  create_artifact "$ARTIFACT_DIR/structure.md" "approved"
  create_artifact "$ARTIFACT_DIR/plan.md" "draft"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/parallelization.md"'","content":"---\nstatus: approved\n---\n"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"plan"* ]]
}

# ──────────────────────────────────────────────────────────────
# [T25-I-N4-B] parallelization.md write with plan approved allows
# ──────────────────────────────────────────────────────────────
@test "[T25-I-N4-B] Write to parallelization.md with plan approved allows (exit 0)" {
  create_artifact "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md" "approved"
  create_artifact "$ARTIFACT_DIR/phasing.md" "approved"
  create_artifact "$ARTIFACT_DIR/structure.md" "approved"
  create_artifact "$ARTIFACT_DIR/plan.md" "approved"

  init_state "$ARTIFACT_DIR"

  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"'"$ARTIFACT_DIR/parallelization.md"'","content":"---\nstatus: approved\n---\n"}}'

  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N5-A] Subagent Write with crafted .. path is rejected (canonicalization)
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N5-A] subagent Write with .. escape is blocked (path canonicalization)" {
  cd "$WORK_DIR"
  mkdir -p .worktrees/x/task-1
  # This path's regex matches via substring `.worktrees/x/task-1/`, but it
  # actually resolves outside the worktree. Pre-canonicalization: pass.
  # Post-canonicalization: blocked (resolves to /tmp/poison or outside worktree).
  local target="$WORK_DIR/.worktrees/x/task-1/../../../../tmp/poison"
  local json='{"agent_id":"sub-1","tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"x"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N5-B] Subagent Write with explicit .. segments rejected even without resolving
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N5-B] subagent Write with .. segments in path is blocked" {
  cd "$WORK_DIR"
  mkdir -p .worktrees/myslug/task-01
  local target="$WORK_DIR/.worktrees/myslug/task-01/../../../etc/poison"
  local json='{"agent_id":"sub-1","tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"x"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [T25-S-N5-C] Subagent Write to legitimate worktree path still allowed
# ──────────────────────────────────────────────────────────────
@test "[T25-S-N5-C] subagent Write to canonical worktree path allows (regression)" {
  cd "$WORK_DIR"
  mkdir -p .worktrees/myslug/task-01/src
  local target="$WORK_DIR/.worktrees/myslug/task-01/src/foo.ts"
  local json='{"agent_id":"sub-1","tool_name":"Write","tool_input":{"file_path":"'"$target"'","content":"x"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# [R2 S-N2] subagent Bash inline interpreter (python -c) blocks
# ──────────────────────────────────────────────────────────────
# A subagent inside a worktree cannot use `python -c` to write outside the
# worktree. The detector emits __OPAQUE_WRITE__ for inline-interpreter
# invocations; the subagent worktree wall checks that "target" against
# `.worktrees/<slug>/(task-NN|baseline)/` and blocks because the sentinel
# is not under any worktree path.
@test "[R2 S-N2] subagent python -c (inline interpreter) blocked by worktree wall" {
  mkdir -p "$WORK_DIR/.worktrees/myslug/task-01"
  cd "$WORK_DIR/.worktrees/myslug/task-01"
  local cmd='python -c "open(\"/tmp/x\",\"w\").write(\"y\")"'
  local json='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [R2 S-N2] subagent Bash dd of=/abs blocked by worktree wall
# ──────────────────────────────────────────────────────────────
@test "[R2 S-N2] subagent dd of=/abs blocked by worktree wall" {
  mkdir -p "$WORK_DIR/.worktrees/myslug/task-01"
  cd "$WORK_DIR/.worktrees/myslug/task-01"
  local cmd='dd if=/dev/zero of=/abs/path bs=1 count=1'
  local json='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [R2 S-N2] subagent no-space redirect outside worktree blocks
# ──────────────────────────────────────────────────────────────
@test "[R2 S-N2] subagent no-space redirect >/abs/poison blocked by worktree wall" {
  mkdir -p "$WORK_DIR/.worktrees/myslug/task-01"
  cd "$WORK_DIR/.worktrees/myslug/task-01"
  local cmd='echo X >/abs/poison'
  local json='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────
# [R2 S-N2] main chat python -c is allowed (sentinel only blocks subagents)
# ──────────────────────────────────────────────────────────────
@test "[R2 S-N2] main chat python -c allowed (no agent_id)" {
  cd "$WORK_DIR"
  # Use escaped double quotes inside the JSON string so the resulting JSON
  # remains well-formed when bats interpolates the command into the JSON
  # body.
  local cmd='python -c \"print(1)\"'
  local json='{"tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
  run "$HOOK" <<< "$json"
  [ "$status" -eq 0 ]
}
