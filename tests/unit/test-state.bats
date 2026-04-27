#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  cd "$TEST_DIR"
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

# Helper function to create a markdown file with frontmatter status
create_artifact() {
  local file="$1"
  local status="$2"
  local dir="$(dirname "$file")"

  mkdir -p "$dir"
  cat > "$file" <<EOF
---
status: $status
---
EOF
}

# Test: state_init_or_reconcile with approved goals.md + draft design.md
@test "state_init_or_reconcile: approved goals, draft design -> current_step=questions" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/design.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  # Verify current_step is "questions"
  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"questions"'* ]]

  # Verify artifact statuses
  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"design":"draft"'* ]]
}

# Test: state_init_or_reconcile with all approved through plan.md
@test "state_init_or_reconcile: all approved through plan -> current_step=implement" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"

  # Create research/summary.md
  mkdir -p "$artifact_dir/research"
  create_artifact "$artifact_dir/research/summary.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"implement"'* ]]
}

# Test: state_init_or_reconcile with empty artifact dir
@test "state_init_or_reconcile: empty artifact dir -> all draft, current_step=goals" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"goals"'* ]]
  [[ "$json" == *'"goals":"draft"'* ]]
  [[ "$json" == *'"questions":"draft"'* ]]
  [[ "$json" == *'"research":"draft"'* ]]
  [[ "$json" == *'"design":"draft"'* ]]
  [[ "$json" == *'"structure":"draft"'* ]]
  [[ "$json" == *'"plan":"draft"'* ]]
  [[ "$json" == *'"implement":"draft"'* ]]
  [[ "$json" == *'"test":"draft"'* ]]
}

# Test: state_init_or_reconcile with missing artifact dir
@test "state_init_or_reconcile: missing artifact dir -> returns 1" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$TEST_DIR/nonexistent"

  [ "$status" -eq 1 ]
}

# Test: state_read when state exists
@test "state_read: state exists -> outputs valid JSON, returns 0" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  run state_read
  [ "$status" -eq 0 ]

  # Verify it's valid JSON by checking with jq
  echo "$output" | jq . > /dev/null
}

# Test: state_read when no state exists
@test "state_read: no state -> returns 1" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_read

  [ "$status" -eq 1 ]
}

# Test: state_write_atomic writes valid JSON
@test "state_write_atomic: writes valid JSON -> file exists with correct content" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local test_json='{"version":1,"current_step":"goals"}'
  run state_write_atomic "$test_json"

  [ "$status" -eq 0 ]

  # Verify file exists
  [ -f "$artifact_dir/.qrspi/state.json" ]

  # Verify content
  local content
  content=$(cat "$artifact_dir/.qrspi/state.json")
  [[ "$content" == *'"version":1'* ]]
  [[ "$content" == *'"current_step":"goals"'* ]]
}

# Test: state_write_atomic creates .qrspi/ if needed
@test "state_write_atomic: creates .qrspi/ if needed" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local test_json='{"version":1}'
  run state_write_atomic "$test_json"

  [ "$status" -eq 0 ]
  [ -d "$artifact_dir/.qrspi" ]
}

# Test: State has version=1
@test "state_init_or_reconcile: state has version=1" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"version":1'* ]]
}

# Test: State has correct artifact_dir
@test "state_init_or_reconcile: state has correct artifact_dir" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  # artifact_dir should be set to the absolute path
  [[ "$json" == *'"artifact_dir"'* ]]
}

# Test: State has wireframe_requested=false
@test "state_init_or_reconcile: state has wireframe_requested=false" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"wireframe_requested":false'* ]]
}

# Test: State has no active_task field (removed in 2026-04-26 implement-runtime-fix)
@test "state_init_or_reconcile: state has no active_task field" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" != *'active_task'* ]]
}

# Test: Recognizes all 8 artifacts
@test "state_init_or_reconcile: recognizes all 8 artifacts" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  # All 8 should be present
  [[ "$json" == *'"goals"'* ]]
  [[ "$json" == *'"questions"'* ]]
  [[ "$json" == *'"research"'* ]]
  [[ "$json" == *'"design"'* ]]
  [[ "$json" == *'"structure"'* ]]
  [[ "$json" == *'"plan"'* ]]
  [[ "$json" == *'"implement"'* ]]
  [[ "$json" == *'"test"'* ]]
}

# Test: Maps research/summary.md to "research" key
@test "state_init_or_reconcile: maps research/summary.md to research key" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/research/summary.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"research":"approved"'* ]]
}

# Test: Library uses set -euo pipefail
@test "state.sh: starts with #!/usr/bin/env bash" {
  head -1 "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh" | grep -q '^#!/usr/bin/env bash'
}

@test "state.sh: has 'set -euo pipefail' as early line" {
  head -2 "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh" | tail -1 | grep -q '^set -euo pipefail'
}

# Test: state_init_or_reconcile reads frontmatter correctly from all artifacts
@test "state_init_or_reconcile: reads frontmatter status from all artifact types" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/structure.md" "draft"
  create_artifact "$artifact_dir/plan.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"questions":"approved"'* ]]
  [[ "$json" == *'"research":"approved"'* ]]
  [[ "$json" == *'"design":"approved"'* ]]
  [[ "$json" == *'"structure":"draft"'* ]]
  [[ "$json" == *'"plan":"draft"'* ]]
}

# Test: current_step is first non-approved artifact in pipeline order
@test "state_init_or_reconcile: current_step is first non-approved in pipeline order" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "draft"
  create_artifact "$artifact_dir/design.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  # research is draft, so it should be current_step
  [[ "$json" == *'"current_step":"research"'* ]]
}

# ============================================================================
# [T04] Fail-closed error handling tests
# ============================================================================

@test "[T04-S1] state_init_or_reconcile: jq failure returns exit 1 with stderr diagnostic" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Sabotage jq by putting a fake jq first in PATH
  local fake_bin="$TEST_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nexit 1\n' > "$fake_bin/jq"
  chmod +x "$fake_bin/jq"

  PATH="$fake_bin:$PATH" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -eq 1 ]
  [[ "$output" == *"jq failed"* ]]
}

@test "[T04-S2] state_write_atomic: no-write .qrspi/ returns exit 1 with stderr diagnostic" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  mkdir -p "$TEST_DIR/.qrspi"
  chmod 555 "$TEST_DIR/.qrspi"

  run state_write_atomic '{"version":1}'
  chmod 755 "$TEST_DIR/.qrspi" 2>/dev/null || true
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed"* ]]
}

@test "[T04-S3] state_init_or_reconcile: binary goals.md defaults to draft with stderr WARNING" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Write binary content to goals.md
  printf '\x00\x01\x02\x03' > "$artifact_dir/goals.md"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local stderr_file="$TEST_DIR/stderr.txt"
  state_init_or_reconcile "$artifact_dir" 2>"$stderr_file"
  local exit_code=$?

  [ "$exit_code" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"goals":"draft"'* ]]

  local stderr_content
  stderr_content=$(cat "$stderr_file")
  [[ "$stderr_content" == *"WARNING"* ]]
  [[ "$stderr_content" == *"cannot read status"* ]]
}

@test "[T04-S4] state_init_or_reconcile: no-write .qrspi/ returns exit 1 with stderr diagnostic" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  mkdir -p "$TEST_DIR/.qrspi"
  chmod 555 "$TEST_DIR/.qrspi"

  run state_init_or_reconcile "$artifact_dir"
  chmod 755 "$TEST_DIR/.qrspi" 2>/dev/null || true
  [ "$status" -eq 1 ]
  [[ "$output" == *"state_write_atomic failed"* ]]
}

# ============================================================================
# [T14] State bootstrap and cascade reset tests
# ============================================================================

@test "[T14-S1] state_init_or_reconcile: approved goals + draft questions + no state.json -> creates state" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "draft"

  # Ensure no state.json exists
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"questions"'* ]]
  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"questions":"draft"'* ]]
}

@test "[T14-S2] state_init_or_reconcile: existing state with goals=approved but goals.md now draft -> reconciles to goals=draft" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # First init: goals=approved
  state_init_or_reconcile "$artifact_dir"
  local json
  json=$(state_read)
  [[ "$json" == *'"goals":"approved"'* ]]

  # Now change goals.md frontmatter to draft
  create_artifact "$artifact_dir/goals.md" "draft"

  # Re-reconcile
  state_init_or_reconcile "$artifact_dir"

  json=$(state_read)
  [[ "$json" == *'"goals":"draft"'* ]]
  [[ "$json" == *'"current_step":"goals"'* ]]
}

@test "[T14-S3] state_init_or_reconcile: called twice -> identical result (idempotency)" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  state_init_or_reconcile "$artifact_dir"
  local json1
  json1=$(state_read)

  state_init_or_reconcile "$artifact_dir"
  local json2
  json2=$(state_read)

  # Compare key fields (artifact_dir may differ in whitespace but content should match)
  local step1 step2 goals1 goals2 questions1 questions2 research1 research2
  step1=$(echo "$json1" | jq -r '.current_step')
  step2=$(echo "$json2" | jq -r '.current_step')
  goals1=$(echo "$json1" | jq -r '.artifacts.goals')
  goals2=$(echo "$json2" | jq -r '.artifacts.goals')
  questions1=$(echo "$json1" | jq -r '.artifacts.questions')
  questions2=$(echo "$json2" | jq -r '.artifacts.questions')
  research1=$(echo "$json1" | jq -r '.artifacts.research')
  research2=$(echo "$json2" | jq -r '.artifacts.research')

  [[ "$step1" == "$step2" ]]
  [[ "$goals1" == "$goals2" ]]
  [[ "$questions1" == "$questions2" ]]
  [[ "$research1" == "$research2" ]]
}

@test "[T14-S4] state_init_or_reconcile: jq produces invalid JSON -> returns non-zero, no state written" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Sabotage jq to output invalid JSON (non-empty but not valid)
  local fake_bin="$TEST_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\necho "not-valid-json{"\nexit 0\n' > "$fake_bin/jq"
  chmod +x "$fake_bin/jq"

  PATH="$fake_bin:$PATH" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]

  # No state file should have been written (or if one existed, it should not be valid)
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]
}

# ============================================================================
# [T04-PHASING] Phasing-step state integration tests (M54)
# ============================================================================

@test "[T04-PHASING-1S] state_init_or_reconcile: includes phasing artifact field with status draft when phasing.md absent" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"phasing":"draft"'* ]]
}

@test "[T04-PHASING-2S] state_init_or_reconcile: reads phasing.md frontmatter status into artifacts.phasing" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/phasing.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"phasing":"approved"'* ]]
}

@test "[T04-PHASING-3S] state_init_or_reconcile: current_step is phasing when goals/questions/research/design approved and phasing draft" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"phasing"'* ]]
}

@test "[T04-PHASING-4S] state_compute_current_step: returns phasing for fixture with phasing draft and upstream approved" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  local out
  out=$(state_compute_current_step "$artifact_dir")
  [[ "$out" == "phasing" ]]
}

@test "[T04-PHASING-5] state_init_or_reconcile fails closed when jq missing and writes no state.json" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Build a minimal PATH containing every shell utility state.sh legitimately
  # uses (mkdir, mv, mktemp, rm, cat, echo, dirname, basename, sh) EXCEPT jq.
  # This isolates the fail-closed-on-jq behavior from any other utility's
  # absence; if PATH were empty, mkdir/mv would also fail and the test could
  # pass for the wrong reason (state_write_atomic failure instead of jq
  # detection).
  local stub_dir="$TEST_DIR/stub-no-jq"
  mkdir -p "$stub_dir"
  local util util_path
  for util in mkdir mv mktemp rm cat echo dirname basename sh chmod; do
    util_path=$(command -v "$util" 2>/dev/null) || true
    if [ -n "$util_path" ]; then
      ln -sf "$util_path" "$stub_dir/$util"
    fi
  done
  # Verify jq is NOT in stub_dir
  [ ! -e "$stub_dir/jq" ]

  # Ensure no state.json initially
  rm -f "$TEST_DIR/.qrspi/state.json"

  PATH="$stub_dir" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]
}

@test "[T04-PHASING-6S] state_init_or_reconcile recognizes all 9 artifacts including phasing" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"goals"'* ]]
  [[ "$json" == *'"questions"'* ]]
  [[ "$json" == *'"research"'* ]]
  [[ "$json" == *'"design"'* ]]
  [[ "$json" == *'"phasing"'* ]]
  [[ "$json" == *'"structure"'* ]]
  [[ "$json" == *'"plan"'* ]]
  [[ "$json" == *'"implement"'* ]]
  [[ "$json" == *'"test"'* ]]
}
