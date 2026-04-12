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

# Test: State has active_task=null
@test "state_init_or_reconcile: state has active_task=null" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"active_task":null'* ]]
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
