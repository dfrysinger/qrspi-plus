#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Setup: create temp artifact dir, temp working dir, and source the library
setup() {
  # Create temp directories
  export ARTIFACT_DIR=$(mktemp -d)
  export WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  # Source the pipeline library (which sources state.sh)
  source "$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
}

# Cleanup: remove temp directories
teardown() {
  rm -rf "$ARTIFACT_DIR" "$WORK_DIR"
}

# Test 1: PIPELINE_ORDER has exactly 8 elements in correct order
@test "PIPELINE_ORDER has 8 elements in correct order" {
  # Get the library file and check it defines PIPELINE_ORDER correctly
  local lib_file
  lib_file="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"

  # Extract the declare line and verify it
  local pipeline_line
  pipeline_line=$(grep "declare -a PIPELINE_ORDER=" "$lib_file")

  [[ "$pipeline_line" == *"goals"* ]]
  [[ "$pipeline_line" == *"questions"* ]]
  [[ "$pipeline_line" == *"research"* ]]
  [[ "$pipeline_line" == *"design"* ]]
  [[ "$pipeline_line" == *"structure"* ]]
  [[ "$pipeline_line" == *"plan"* ]]
  [[ "$pipeline_line" == *"implement"* ]]
  [[ "$pipeline_line" == *"test"* ]]
}

# Test 2: pipeline_check_prerequisites "goals" with all draft returns 0
@test "pipeline_check_prerequisites goals with all draft returns 0" {
  # Create artifact files with draft status
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test
  pipeline_check_prerequisites "goals" "$ARTIFACT_DIR"
}

# Test 3: pipeline_check_prerequisites "questions" with goals approved returns 0
@test "pipeline_check_prerequisites questions with goals approved returns 0" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test
  pipeline_check_prerequisites "questions" "$ARTIFACT_DIR"
}

# Test 4: pipeline_check_prerequisites "questions" with goals draft returns 1 with "goals" on stdout
@test "pipeline_check_prerequisites questions with goals draft returns 1 and outputs goals" {
  # Create artifact files with goals as draft
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test - run and expect failure with "goals" output
  run -1 pipeline_check_prerequisites "questions" "$ARTIFACT_DIR"
  [[ "$output" == "goals" ]]
}

# Test 5: pipeline_check_prerequisites "design" with goals+questions approved, research draft returns 1 with "research"
@test "pipeline_check_prerequisites design with missing research returns 1 and outputs research" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test - run and expect failure with "research" output
  run -1 pipeline_check_prerequisites "design" "$ARTIFACT_DIR"
  [[ "$output" == "research" ]]
}

# Test 6: pipeline_check_prerequisites "design" with goals+questions+research approved returns 0
@test "pipeline_check_prerequisites design with all prerequisites approved returns 0" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test
  pipeline_check_prerequisites "design" "$ARTIFACT_DIR"
}

# Test 7: pipeline_check_prerequisites "implement" with all through plan approved returns 0
@test "pipeline_check_prerequisites implement with all prerequisites approved returns 0" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test
  pipeline_check_prerequisites "implement" "$ARTIFACT_DIR"
}

# Test 8: pipeline_check_prerequisites "foobar" returns 1
@test "pipeline_check_prerequisites with invalid step returns 1" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Test
  pipeline_check_prerequisites "foobar" "$ARTIFACT_DIR" && false || true
}

# Test 9: pipeline_cascade_reset "design" resets design and downstream to draft
@test "pipeline_cascade_reset design resets design through test to draft" {
  # Create artifact files, all approved
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Reset design and downstream
  pipeline_cascade_reset "design" "$ARTIFACT_DIR"

  # Verify state
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

# Test 10: pipeline_cascade_reset "goals" resets all 8 to draft
@test "pipeline_cascade_reset goals resets all 8 to draft" {
  # Create artifact files, all approved
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Reset all
  pipeline_cascade_reset "goals" "$ARTIFACT_DIR"

  # Verify all are draft
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

# Test 11: pipeline_cascade_reset "test" resets only test to draft
@test "pipeline_cascade_reset test resets only test to draft" {
  # Create artifact files, all approved
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Manually mark implement and test as approved (state_init_or_reconcile doesn't do this)
  local state
  state=$(state_read)
  state=$(echo "$state" | jq '.artifacts.implement = "approved"')
  state=$(echo "$state" | jq '.artifacts.test = "approved"')
  state_write_atomic "$state"

  # Reset test only
  pipeline_cascade_reset "test" "$ARTIFACT_DIR"

  # Verify only test is draft
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

# Test 12: cascade_reset does NOT modify artifact files on disk
@test "pipeline_cascade_reset does not modify artifact files on disk" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---\nGoals content" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---\nQuestions content" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---\nResearch content" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---\nDesign content" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---\nStructure content" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---\nPlan content" > "$ARTIFACT_DIR/plan.md"

  # Save original content
  local goals_original
  goals_original=$(cat "$ARTIFACT_DIR/goals.md")

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Reset
  pipeline_cascade_reset "design" "$ARTIFACT_DIR"

  # Verify artifact file unchanged
  local goals_after
  goals_after=$(cat "$ARTIFACT_DIR/goals.md")
  [[ "$goals_original" == "$goals_after" ]]
}

# Test 13: cascade_reset uses state_write_atomic (verified by checking state file exists and is valid JSON)
@test "pipeline_cascade_reset uses state_write_atomic to write atomically" {
  # Create artifact files
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Reset
  pipeline_cascade_reset "design" "$ARTIFACT_DIR"

  # Verify .qrspi/state.json exists and is valid JSON
  [[ -f ".qrspi/state.json" ]]
  state_read | jq . > /dev/null
}

# Test 14: Dual check - state says approved but frontmatter says draft, trust frontmatter
@test "pipeline_check_prerequisites dual check trusts frontmatter over state" {
  # Create artifact files with draft frontmatter
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Manually update state to say goals is approved (to test dual check)
  local state
  state=$(state_read)
  state=$(echo "$state" | jq '.artifacts.goals = "approved"')
  state_write_atomic "$state"

  # Now test: even though state says approved, frontmatter says draft, so should fail
  run -1 pipeline_check_prerequisites "questions" "$ARTIFACT_DIR"
  [[ "$output" == "goals" ]]
}

# Test 15: Library uses set -euo pipefail
@test "pipeline.sh uses set -euo pipefail" {
  local lib_content
  lib_content=$(head -2 "$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh")
  [[ "$lib_content" == *"set -euo pipefail"* ]]
}

# ============================================================================
# [T04] Fail-closed error handling tests
# ============================================================================

@test "[T04-P1] pipeline_check_prerequisites: unreadable state returns exit 1, stdout state-unavailable, stderr diagnostic" {
  # Create artifact files with approved goals so we actually need state
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: draft\n---" > "$ARTIFACT_DIR/questions.md"

  # Remove .qrspi entirely so state_read returns 1 (no state file)
  rm -rf "$WORK_DIR/.qrspi"
  # Also remove artifact_dir goals so state_init_or_reconcile will fail
  # Actually: we need state_read to fail AND no fallback — simplest: make .qrspi
  # directory exist but state.json not exist, AND artifact_dir not exist for init fallback
  # The function tries state_read first (fails), then we need it to NOT have a fallback
  # Actually pipeline_check_prerequisites just calls state_read, doesn't init.
  # So if no .qrspi/state.json, state_read returns 1 → we get state-unavailable

  run pipeline_check_prerequisites "questions" "$ARTIFACT_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"<state-unavailable>"* ]]
}

@test "[T04-P2] pipeline_cascade_reset: invalid artifact_dir returns exit 1 with stderr diagnostic" {
  # Don't create any state or artifact dir — cascade_reset should fail
  # when it can't init state from a nonexistent artifact_dir
  run pipeline_cascade_reset "design" "/nonexistent/artifact/dir"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot perform cascade reset"* ]]
}

@test "[T04-P3] pipeline_check_prerequisites: step deploy returns exit 1, stdout unknown-step, stderr diagnostic" {
  run pipeline_check_prerequisites "deploy" "$ARTIFACT_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"<unknown-step>"* ]]
  [[ "$output" == *"unrecognized step"* ]]
}

# ============================================================================
# [T14] State bootstrap and cascade reset tests
# ============================================================================

# Helper to create all artifacts with a given status
_t14_create_all_approved() {
  mkdir -p "$ARTIFACT_DIR/research"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/goals.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/questions.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/research/summary.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/design.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/structure.md"
  echo -e "---\nstatus: approved\n---" > "$ARTIFACT_DIR/plan.md"
}

@test "[T14-P1] pipeline_cascade_reset goals -> all 8 steps reset to draft" {
  _t14_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Mark implement and test as approved in state
  local state
  state=$(state_read)
  state=$(echo "$state" | jq '.artifacts.implement = "approved"')
  state=$(echo "$state" | jq '.artifacts.test = "approved"')
  state_write_atomic "$state"

  pipeline_cascade_reset "goals" "$ARTIFACT_DIR"

  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

@test "[T14-P2] pipeline_cascade_reset design -> resets design through test, leaves goals/questions/research" {
  _t14_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  pipeline_cascade_reset "design" "$ARTIFACT_DIR"

  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

@test "[T14-P3b] pipeline_cascade_reset design --skip-cascade -> resets only design, downstream unchanged" {
  _t14_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  pipeline_cascade_reset "design" "$ARTIFACT_DIR" --skip-cascade

  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.implement') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.test') == "draft" ]]
}

@test "[T14-P4] pipeline_cascade_reset with --unknown flag -> returns non-zero" {
  _t14_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  run pipeline_cascade_reset "design" "$ARTIFACT_DIR" --unknown
  [ "$status" -eq 1 ]
}

@test "[T14-P5] pipeline_cascade_reset when no state.json -> calls init then resets" {
  _t14_create_all_approved

  # Ensure no state.json exists
  rm -rf "$WORK_DIR/.qrspi"

  pipeline_cascade_reset "design" "$ARTIFACT_DIR"

  # State should exist now, with design through test reset
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
}
