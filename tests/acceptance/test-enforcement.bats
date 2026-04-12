#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 2 — Enforcement (non-audit portions):
# "During implementation, file writes outside the plan's allowlist are either
#  blocked (strict mode) or logged for post-task audit (monitored mode)"
#
# Covers:
#   - Strict mode allowlist blocking via Write/Edit tools
#   - Monitored mode: writes allowed regardless of allowlist
#   - Bash tool file-write detection (>, sed -i, cp, mv, tee patterns)
#   - Worktree containment: blocks writes outside worktree boundary
#   - Protected paths: blocks task spec, state.json, config from worktree agents
#   - Approve/switch/reject interaction model hints in block message
#
# Tests operate end-to-end through the pre-tool-use hook.

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  export ARTIFACT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$WORK_DIR/.qrspi"
  cd "$WORK_DIR"

  export HOOK
  HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
}

teardown() {
  rm -rf "$WORK_DIR"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

create_task_spec() {
  local task_num="$1"
  local enforcement="$2"
  shift 2
  # Remaining args are allowed file paths (relative)
  local allowed_block=""
  for p in "$@"; do
    allowed_block="${allowed_block}  - action: create\n    path: ${p}\n"
  done
  printf -- '---\nstatus: approved\ntask: %s\nphase: 1\nenforcement: %s\nallowed_files:\n%s\nconstraints: []\n---\n\n# Task %s\n' \
    "$task_num" "$enforcement" "$(printf '%b' "$allowed_block")" "$task_num" \
    > "$ARTIFACT_DIR/tasks/task-$(printf '%02d' "$task_num").md"
}

# Initialise state with a given active_task id (no pipeline artifacts needed for enforcement tests)
init_state_with_task() {
  local task_id="$1"
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$ARTIFACT_DIR" && pwd)"
  jq -cn \
    --arg version "1" \
    --arg artifact_dir "$abs_artifact_dir" \
    --argjson task_id "$task_id" \
    '{version:1, current_step:"implement", phase_start_commit:null,
      artifact_dir:$artifact_dir, wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:$task_id}}' > "$WORK_DIR/.qrspi/state.json"
}

write_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$file_path"
}

edit_json() {
  local file_path="$1"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"a","new_string":"b"}}\n' "$file_path"
}

bash_json() {
  local cmd="$1"
  # Escape backslashes and double quotes for inline JSON
  local escaped_cmd="${cmd//\\/\\\\}"
  escaped_cmd="${escaped_cmd//\"/\\\"}"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}\n' "$escaped_cmd"
}

# ── Criterion 2: Strict mode Write/Edit allowlist ────────────────────────────

# AC2 — Strict mode: file in allowed_files is allowed
@test "[AC2][strict] Write to allowed file in strict mode → exit 0" {
  create_task_spec 1 "strict" "src/main.sh"
  init_state_with_task 1

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/main.sh")"
  [ "$status" -eq 0 ]
}

# AC2 — Strict mode: file NOT in allowed_files is blocked
@test "[AC2][strict] Write to file not in allowed_files in strict mode → exit 2" {
  create_task_spec 2 "strict" "src/main.sh"
  init_state_with_task 2

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/other.sh")"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]
}

# AC2 — Strict mode: Edit to file NOT in allowed_files is blocked
@test "[AC2][strict] Edit to file not in allowed_files in strict mode → exit 2" {
  create_task_spec 3 "strict" "src/main.sh"
  init_state_with_task 3

  run "$HOOK" <<< "$(edit_json "$WORK_DIR/src/not-allowed.sh")"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]
}

# AC2 — Strict mode block message includes approve/switch/reject interaction hints
@test "[AC2][strict] Block message mentions approve, switch, reject interaction options" {
  create_task_spec 4 "strict" "src/main.sh"
  init_state_with_task 4

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/unlisted.sh")"
  [ "$status" -eq 2 ]
  # The block reason must guide the agent on what to do
  [[ "$output" == *"approve"* ]] || [[ "$output" == *"switch"* ]] || [[ "$output" == *"reject"* ]] || \
    [[ "$output" == *"Ask user"* ]] || [[ "$output" == *"Options"* ]]
}

# ── Criterion 2: Runtime runtime overrides user_approved_files override ────────────────

# AC2 — Strict mode: file in runtime overrides user_approved_files is allowed even if not in spec
@test "[AC2][runtime overrides] File in user_approved_files runtime runtime overrides is allowed in strict mode → exit 0" {
  create_task_spec 5 "strict" "src/main.sh"
  init_state_with_task 5

  # Write runtime overrides with extra approved file
  printf '{"enforcement":"strict","user_approved_files":["src/extra.sh"]}' \
    > "$WORK_DIR/.qrspi/task-05-runtime.json"

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/extra.sh")"
  [ "$status" -eq 0 ]
}

# AC2 — Sidecar enforcement=monitored overrides task spec strict
@test "[AC2][runtime overrides] Sidecar enforcement=monitored overrides strict task spec → write allowed" {
  create_task_spec 6 "strict" "src/main.sh"
  init_state_with_task 6

  printf '{"enforcement":"monitored","user_approved_files":[]}' \
    > "$WORK_DIR/.qrspi/task-06-runtime.json"

  # Write to a file that is not in the task spec's allowed_files
  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/anything.sh")"
  [ "$status" -eq 0 ]
}

# ── Criterion 2: Monitored mode ──────────────────────────────────────────────

# AC2 — Monitored mode: any file write is allowed
@test "[AC2][monitored] Any file write allowed in monitored mode → exit 0" {
  create_task_spec 7 "monitored"
  init_state_with_task 7

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/anything-at-all.sh")"
  [ "$status" -eq 0 ]
}

# AC2 — Pre-Phase-4 task spec (no enforcement field) defaults to strict (fail-closed): blocks writes
@test "[AC2][strict] Pre-Phase-4 task spec defaults to strict (fail-closed) → write blocked" {
  # Task spec without enforcement/allowed_files/constraints (old format)
  printf -- '---\nstatus: approved\ntask: 8\nphase: 1\n---\n\n# Task 8\n' \
    > "$ARTIFACT_DIR/tasks/task-08.md"
  init_state_with_task 8

  run "$HOOK" <<< "$(write_json "$WORK_DIR/src/whatever.sh")"
  [ "$status" -eq 2 ]
}

# ── Criterion 2: Bash tool file-write detection ──────────────────────────────

# AC2 — Bash redirect (>) to allowed file in strict mode is allowed
@test "[AC2][bash-detect] Bash redirect > to allowed file in strict mode → exit 0" {
  create_task_spec 9 "strict" "out/result.txt"
  init_state_with_task 9

  run "$HOOK" <<< "$(bash_json "echo hello > out/result.txt")"
  [ "$status" -eq 0 ]
}

# AC2 — Bash redirect (>) to non-allowed file in strict mode is blocked
@test "[AC2][bash-detect] Bash redirect > to non-allowed file in strict mode → exit 2" {
  create_task_spec 10 "strict" "out/result.txt"
  init_state_with_task 10

  run "$HOOK" <<< "$(bash_json "echo hello > out/forbidden.txt")"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]
}

# AC2 — Bash append (>>) to non-allowed file in strict mode is blocked
@test "[AC2][bash-detect] Bash append >> to non-allowed file in strict mode → exit 2" {
  create_task_spec 11 "strict" "out/result.txt"
  init_state_with_task 11

  run "$HOOK" <<< "$(bash_json "echo more >> out/forbidden.txt")"
  [ "$status" -eq 2 ]
}

# AC2 — Bash tee to non-allowed file in strict mode is blocked
@test "[AC2][bash-detect] Bash tee to non-allowed file in strict mode → exit 2" {
  create_task_spec 12 "strict" "out/result.txt"
  init_state_with_task 12

  run "$HOOK" <<< "$(bash_json "cat data.txt | tee out/snapshot.txt")"
  [ "$status" -eq 2 ]
}

# AC2 — Bash cp to non-allowed destination in strict mode is blocked
@test "[AC2][bash-detect] Bash cp to non-allowed destination in strict mode → exit 2" {
  create_task_spec 13 "strict" "out/result.txt"
  init_state_with_task 13

  run "$HOOK" <<< "$(bash_json "cp src.sh out/copy.sh")"
  [ "$status" -eq 2 ]
}

# AC2 — Bash with no file-write patterns in strict mode is allowed
@test "[AC2][bash-detect] Bash read-only command with no file writes in strict mode → exit 0" {
  create_task_spec 14 "strict" "out/result.txt"
  init_state_with_task 14

  run "$HOOK" <<< "$(bash_json "cat file.txt && grep pattern file.txt")"
  [ "$status" -eq 0 ]
}

# ── Criterion 2: Worktree containment ────────────────────────────────────────

# AC2 — Inside a worktree: write to file inside worktree boundary is allowed
@test "[AC2][worktree] Write inside worktree boundary → exit 0" {
  create_task_spec 1 "monitored"
  # Simulate a worktree CWD by creating a path that matches /.worktrees/ pattern
  local worktree_dir
  worktree_dir=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$worktree_dir/.worktrees/task-01"
  mkdir -p "$worktree_dir/.worktrees/task-01/.qrspi"

  # State in the worktree directory
  local abs_artifact_dir
  abs_artifact_dir="$(cd "$ARTIFACT_DIR" && pwd)"
  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:1}}' > "$worktree_dir/.worktrees/task-01/.qrspi/state.json"

  # Run hook from within the worktree
  local target_file="$worktree_dir/.worktrees/task-01/src/main.sh"
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$target_file")

  run bash -c "cd '$worktree_dir/.worktrees/task-01' && '$HOOK' <<< '$json'"
  # Containment check: file is inside worktree, should be allowed
  [ "$status" -eq 0 ]

  rm -rf "$worktree_dir"
}

# AC2 — Inside a worktree: write to file outside worktree boundary is blocked
@test "[AC2][worktree] Write outside worktree boundary → exit 2 with containment violation" {
  # Create a worktree directory structure
  local worktree_dir
  worktree_dir=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$worktree_dir/.worktrees/task-02"
  mkdir -p "$worktree_dir/.worktrees/task-02/.qrspi"
  mkdir -p "$worktree_dir/.worktrees/task-02/artifacts/tasks"

  local abs_artifact_dir="$worktree_dir/.worktrees/task-02/artifacts"
  printf -- '---\nstatus:approved\ntask:2\nphase:1\nenforcement:monitored\nallowed_files:[]\nconstraints:[]\n---\n\n# Task 2\n' \
    > "$abs_artifact_dir/tasks/task-02.md"

  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:2}}' > "$worktree_dir/.worktrees/task-02/.qrspi/state.json"

  # Target is outside the worktree boundary — in parent project directory
  local outside_file="$worktree_dir/main-project/hooks/lib/secret.sh"
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$outside_file")

  run bash -c "cd '$worktree_dir/.worktrees/task-02' && '$HOOK' <<< '$json'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"containment"* ]] || [[ "$output" == *"outside"* ]] || [[ "$output" == *"boundary"* ]]

  rm -rf "$worktree_dir"
}

# ── Criterion 2: Protected paths ─────────────────────────────────────────────

# AC2 — Inside a worktree: writing to tasks/task-NN.md is blocked (protected)
@test "[AC2][protected] Write to tasks/task-NN.md from worktree is blocked → exit 2" {
  local worktree_dir
  worktree_dir=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$worktree_dir/.worktrees/task-03"
  mkdir -p "$worktree_dir/.worktrees/task-03/.qrspi"
  mkdir -p "$worktree_dir/.worktrees/task-03/artifacts/tasks"

  local abs_artifact_dir="$worktree_dir/.worktrees/task-03/artifacts"
  printf -- '---\nstatus:approved\ntask:3\nphase:1\nenforcement:monitored\nallowed_files:[]\nconstraints:[]\n---\n\n# Task 3\n' \
    > "$abs_artifact_dir/tasks/task-03.md"

  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:3}}' > "$worktree_dir/.worktrees/task-03/.qrspi/state.json"

  # Target is the task spec file inside the worktree — protected path
  local target_file="$worktree_dir/.worktrees/task-03/tasks/task-03.md"
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"tampered"}}\n' "$target_file")

  run bash -c "cd '$worktree_dir/.worktrees/task-03' && '$HOOK' <<< '$json'"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]

  rm -rf "$worktree_dir"
}

# AC2 — Inside a worktree: writing to .qrspi/state.json is blocked (protected)
@test "[AC2][protected] Write to .qrspi/state.json from worktree is blocked → exit 2" {
  local worktree_dir
  worktree_dir=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$worktree_dir/.worktrees/task-04"
  mkdir -p "$worktree_dir/.worktrees/task-04/.qrspi"
  mkdir -p "$worktree_dir/.worktrees/task-04/artifacts/tasks"

  local abs_artifact_dir="$worktree_dir/.worktrees/task-04/artifacts"
  printf -- '---\nstatus:approved\ntask:4\nphase:1\nenforcement:monitored\nallowed_files:[]\nconstraints:[]\n---\n\n# Task 4\n' \
    > "$abs_artifact_dir/tasks/task-04.md"

  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:4}}' > "$worktree_dir/.worktrees/task-04/.qrspi/state.json"

  local target_file="$worktree_dir/.worktrees/task-04/.qrspi/state.json"
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"{}"}}\n' "$target_file")

  run bash -c "cd '$worktree_dir/.worktrees/task-04' && '$HOOK' <<< '$json'"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]

  rm -rf "$worktree_dir"
}

# AC2 — Inside a worktree: writing to config.md is blocked (protected)
@test "[AC2][protected] Write to config.md from worktree is blocked → exit 2" {
  local worktree_dir
  worktree_dir=$(mktemp -d "/tmp/project.XXXXXX")
  mkdir -p "$worktree_dir/.worktrees/task-05"
  mkdir -p "$worktree_dir/.worktrees/task-05/.qrspi"
  mkdir -p "$worktree_dir/.worktrees/task-05/artifacts/tasks"

  local abs_artifact_dir="$worktree_dir/.worktrees/task-05/artifacts"
  printf -- '---\nstatus:approved\ntask:5\nphase:1\nenforcement:monitored\nallowed_files:[]\nconstraints:[]\n---\n\n# Task 5\n' \
    > "$abs_artifact_dir/tasks/task-05.md"

  jq -cn --arg artifact_dir "$abs_artifact_dir" \
    '{version:1,current_step:"implement",phase_start_commit:null,
      artifact_dir:$artifact_dir,wireframe_requested:false,
      artifacts:{goals:"approved",questions:"approved",research:"approved",
                 design:"approved",structure:"approved",plan:"approved",
                 implement:"draft",test:"draft"},
      active_task:{id:5}}' > "$worktree_dir/.worktrees/task-05/.qrspi/state.json"

  local target_file="$worktree_dir/.worktrees/task-05/config.md"
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"tampered"}}\n' "$target_file")

  run bash -c "cd '$worktree_dir/.worktrees/task-05' && '$HOOK' <<< '$json'"
  [ "$status" -eq 2 ]
  [[ "$(echo "${lines[-1]}" | jq -r '.decision')" == "block" ]]

  rm -rf "$worktree_dir"
}
