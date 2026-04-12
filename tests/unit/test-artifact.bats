#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  # Create temp directories
  export ARTIFACT_DIR=$(mktemp -d)
  export WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  # Source the artifact library (which sources pipeline.sh)
  source "$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/artifact.sh"
}

teardown() {
  rm -rf "$ARTIFACT_DIR" "$WORK_DIR"
}

# Helper function to create a markdown file with frontmatter
create_artifact_file() {
  local file="$1"
  local status="$2"
  local wireframe_requested="${3:-}"
  local dir="$(dirname "$file")"

  mkdir -p "$dir"

  if [[ -z "$wireframe_requested" ]]; then
    cat > "$file" <<EOF
---
status: $status
---
EOF
  else
    cat > "$file" <<EOF
---
status: $status
wireframe_requested: $wireframe_requested
---
EOF
  fi
}

# Test 1: ARTIFACT_FILES has exactly 6 entries
@test "ARTIFACT_FILES has exactly 6 entries" {
  # Check in the library file
  local lib_file
  lib_file="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/artifact.sh"

  # Verify the array contains all 6 paths
  local content
  content=$(sed -n '/^declare -a ARTIFACT_FILES=/,/^)/p' "$lib_file")
  [[ "$content" == *"goals.md"* ]]
  [[ "$content" == *"questions.md"* ]]
  [[ "$content" == *"research/summary.md"* ]]
  [[ "$content" == *"design.md"* ]]
  [[ "$content" == *"structure.md"* ]]
  [[ "$content" == *"plan.md"* ]]

  # Count lines with .md entries to verify exactly 6
  local line_count
  line_count=$(echo "$content" | grep -c '\.md' || echo 0)
  [[ "$line_count" -eq 6 ]]
}

# Test 2: Library uses set -euo pipefail
@test "Library uses set -euo pipefail" {
  local lib_file
  lib_file="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/artifact.sh"

  [[ $(head -2 "$lib_file") == *"set -euo pipefail"* ]]
}

# Test 3: Library sources pipeline.sh
@test "Library sources pipeline.sh" {
  local lib_file
  lib_file="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/artifact.sh"

  [[ $(cat "$lib_file") == *"source"*"pipeline.sh"* ]]
}

# Test 4: artifact_is_known with goals.md returns 0 and outputs "goals"
@test "artifact_is_known goals.md returns 0 and outputs 'goals'" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/goals.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "goals" ]
}

# Test 5: artifact_is_known with research/summary.md returns 0 and outputs "research"
@test "artifact_is_known research/summary.md returns 0 and outputs 'research'" {
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/research/summary.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "research" ]
}

# Test 6: artifact_is_known with design.md returns 0 and outputs "design"
@test "artifact_is_known design.md returns 0 and outputs 'design'" {
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "design" ]
}

# Test 7: artifact_is_known with questions.md returns 0 and outputs "questions"
@test "artifact_is_known questions.md returns 0 and outputs 'questions'" {
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/questions.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "questions" ]
}

# Test 8: artifact_is_known with structure.md returns 0 and outputs "structure"
@test "artifact_is_known structure.md returns 0 and outputs 'structure'" {
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/structure.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "structure" ]
}

# Test 9: artifact_is_known with plan.md returns 0 and outputs "plan"
@test "artifact_is_known plan.md returns 0 and outputs 'plan'" {
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  run artifact_is_known "$ARTIFACT_DIR/plan.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "plan" ]
}

# Test 10: artifact_is_known with hooks/lib/task.sh returns 1
@test "artifact_is_known hooks/lib/task.sh returns 1" {
  mkdir -p "$WORK_DIR/hooks/lib"
  echo "# dummy" > "$WORK_DIR/hooks/lib/task.sh"

  run artifact_is_known "$WORK_DIR/hooks/lib/task.sh" "$ARTIFACT_DIR"

  [ "$status" -eq 1 ]
}

# Test 11: artifact_is_known with some-other-goals.md outside artifact dir returns 1
@test "artifact_is_known some-other-goals.md outside artifact dir returns 1" {
  mkdir -p "$WORK_DIR/other"
  echo "# dummy" > "$WORK_DIR/other/some-other-goals.md"

  run artifact_is_known "$WORK_DIR/other/some-other-goals.md" "$ARTIFACT_DIR"

  [ "$status" -eq 1 ]
}

# Test 12: artifact_is_known with absolute path works
@test "artifact_is_known with absolute path works" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  local abs_path
  abs_path="$(cd "$ARTIFACT_DIR" && pwd)/goals.md"

  run artifact_is_known "$abs_path" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "goals" ]
}

# Test 13: artifact_sync_state on approved artifact updates state to approved
@test "artifact_sync_state on approved artifact updates state to approved" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Update goals.md to approved
  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"

  # Sync state
  artifact_sync_state "$ARTIFACT_DIR/goals.md" "$ARTIFACT_DIR"

  # Verify state was updated using jq
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
}

# Test 14: artifact_sync_state on draft artifact triggers cascade reset
@test "artifact_sync_state on draft artifact triggers cascade reset" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state with some approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Verify initial state
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]

  # Update questions to draft
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"

  # Sync state
  artifact_sync_state "$ARTIFACT_DIR/questions.md" "$ARTIFACT_DIR"

  # Verify cascade reset occurred using jq
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
}

# Test 15: artifact_sync_state cascade: resetting design resets structure and plan
@test "artifact_sync_state cascade: design reset resets structure and plan" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/design.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "approved"

  # Initialize state with all approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Update design to draft
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"

  # Sync state
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  # Verify cascade reset using jq
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
  # But goals, questions, research should remain approved
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
}

# Test 16: artifact_sync_state on design.md with wireframe_requested:true syncs to state
@test "artifact_sync_state design.md with wireframe_requested:true syncs to state" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft" "true"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state with design.md
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  # Verify wireframe_requested was synced using jq
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.wireframe_requested') == "true" ]]
}

# Test 17: artifact_sync_state on design.md with wireframe_requested:false syncs to state
@test "artifact_sync_state design.md with wireframe_requested:false syncs to state" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft" "false"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state with design.md
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  # Verify wireframe_requested was synced using jq
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.wireframe_requested') == "false" ]]
}

# Test 18: artifact_sync_state on design.md without wireframe_requested doesn't error
@test "artifact_sync_state design.md without wireframe_requested doesn't error" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state with design.md (no wireframe_requested field)
  run artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  [ "$status" -eq 0 ]
}

# Test 19: artifact_sync_state on non-design.md doesn't attempt wireframe sync
@test "artifact_sync_state goals.md doesn't sync wireframe_requested" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft" "true"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state with goals.md
  artifact_sync_state "$ARTIFACT_DIR/goals.md" "$ARTIFACT_DIR"

  # Verify wireframe_requested is still false using jq (not synced from goals)
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.wireframe_requested') == "false" ]]
}

# Test 20: wireframe_requested beyond line 10 in frontmatter is parsed correctly
@test "artifact_sync_state design.md with wireframe_requested beyond line 10 parses correctly" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "draft"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Create design.md with wireframe_requested well past line 10
  cat > "$ARTIFACT_DIR/design.md" <<'DESIGNEOF'
---
status: draft
title: Big Design
author: Test Author
description: A very long description
category: architecture
phase: 4
priority: high
reviewer: nobody
tags: foo bar baz
notes: extra notes here
wireframe_requested: true
---

# Design content
DESIGNEOF

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state with design.md
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  # Verify wireframe_requested was synced — proves no line-10 limit
  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.wireframe_requested') == "true" ]]
}

# Test 21: State written atomically (file exists after write)
@test "artifact_sync_state writes state atomically" {
  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "draft"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "draft"

  # Initialize state
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Sync state
  artifact_sync_state "$ARTIFACT_DIR/goals.md" "$ARTIFACT_DIR"

  # Verify state file exists and is valid JSON
  [[ -f ".qrspi/state.json" ]]

  local state
  state=$(state_read)
  [[ -n "$state" ]]

  # Verify it's valid JSON
  echo "$state" | jq . >/dev/null 2>&1
}

# ============================================================================
# [T15] artifact_sync_state with --skip-cascade tests
# ============================================================================

# Helper to create all artifacts with approved status
_t15_create_all_approved() {
  mkdir -p "$ARTIFACT_DIR/research"
  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/design.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "approved"
}

@test "[T15-A1] artifact_sync_state design.md (draft, no flag) -> full cascade from design" {
  _t15_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Set design to draft on disk
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"

  # Sync without --skip-cascade
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR"

  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
}

@test "[T15-A2] artifact_sync_state design.md (draft, --skip-cascade) -> resets only design" {
  _t15_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Set design to draft on disk
  create_artifact_file "$ARTIFACT_DIR/design.md" "draft"

  # Sync with --skip-cascade
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR" --skip-cascade

  local state
  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.goals') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.questions') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.research') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.design') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "approved" ]]
}

@test "[T15-A3] artifact_sync_state design.md (approved, --skip-cascade) -> sets design=approved, no downstream changes" {
  _t15_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  # Manually set structure and plan to draft in state to verify they stay untouched
  local state
  state=$(state_read)
  state=$(echo "$state" | jq '.artifacts.structure = "draft"')
  state=$(echo "$state" | jq '.artifacts.plan = "draft"')
  state_write_atomic "$state"

  # design.md stays approved on disk
  artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR" --skip-cascade

  state=$(state_read)
  [[ $(echo "$state" | jq -r '.artifacts.design') == "approved" ]]
  [[ $(echo "$state" | jq -r '.artifacts.structure') == "draft" ]]
  [[ $(echo "$state" | jq -r '.artifacts.plan') == "draft" ]]
}

@test "[T15-A4] artifact_sync_state with unknown flag -> returns non-zero" {
  _t15_create_all_approved
  state_init_or_reconcile "$ARTIFACT_DIR"

  run artifact_sync_state "$ARTIFACT_DIR/design.md" "$ARTIFACT_DIR" --bogus-flag
  [ "$status" -ne 0 ]
}

# ============================================================================
# [T16] artifact_snapshot_phase and artifact_promote_next_phase tests
# ============================================================================

# Helper to set up a full artifact directory for snapshot tests
_t16_setup_artifact_dir() {
  mkdir -p "$ARTIFACT_DIR/research"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$ARTIFACT_DIR/reviews"
  mkdir -p "$ARTIFACT_DIR/fixes"
  mkdir -p "$ARTIFACT_DIR/feedback"
  mkdir -p "$ARTIFACT_DIR/.qrspi"

  create_artifact_file "$ARTIFACT_DIR/goals.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/questions.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/design.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/structure.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/plan.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/tasks/task-01.md" "approved"
  create_artifact_file "$ARTIFACT_DIR/tasks/task-02.md" "approved"
  echo "slice: alpha" > "$ARTIFACT_DIR/tasks/parallelization.md"
  echo "review notes" > "$ARTIFACT_DIR/reviews/review-01.md"
  echo "fix notes" > "$ARTIFACT_DIR/fixes/fix-01.md"
  echo "feedback notes" > "$ARTIFACT_DIR/feedback/replan-phase-01-round-01.md"
  echo '{"phase":1}' > "$ARTIFACT_DIR/.qrspi/state.json"
  echo "codex_reviews: false" > "$ARTIFACT_DIR/config.md"
}

@test "[T16-1] artifact_snapshot_phase creates phases/phase-01/ with goals.md, design.md, research/summary.md" {
  _t16_setup_artifact_dir

  run artifact_snapshot_phase "$ARTIFACT_DIR" 1

  [ "$status" -eq 0 ]
  [ -f "$ARTIFACT_DIR/phases/phase-01/goals.md" ]
  [ -f "$ARTIFACT_DIR/phases/phase-01/design.md" ]
  [ -f "$ARTIFACT_DIR/phases/phase-01/research/summary.md" ]
}

@test "[T16-2] snapshot files retain original status: approved frontmatter" {
  _t16_setup_artifact_dir

  artifact_snapshot_phase "$ARTIFACT_DIR" 1

  local snapshot_status
  snapshot_status=$(frontmatter_get "$ARTIFACT_DIR/phases/phase-01/goals.md" "status")
  [ "$snapshot_status" = "approved" ]

  snapshot_status=$(frontmatter_get "$ARTIFACT_DIR/phases/phase-01/design.md" "status")
  [ "$snapshot_status" = "approved" ]
}

@test "[T16-3] snapshot copies tasks/task-NN.md files" {
  _t16_setup_artifact_dir

  artifact_snapshot_phase "$ARTIFACT_DIR" 1

  [ -f "$ARTIFACT_DIR/phases/phase-01/tasks/task-01.md" ]
  [ -f "$ARTIFACT_DIR/phases/phase-01/tasks/task-02.md" ]
}

@test "[T16-4] snapshot does NOT copy reviews/, fixes/, feedback/, config.md" {
  _t16_setup_artifact_dir

  artifact_snapshot_phase "$ARTIFACT_DIR" 1

  [ ! -d "$ARTIFACT_DIR/phases/phase-01/reviews" ]
  [ ! -d "$ARTIFACT_DIR/phases/phase-01/fixes" ]
  [ ! -d "$ARTIFACT_DIR/phases/phase-01/feedback" ]
  [ ! -f "$ARTIFACT_DIR/phases/phase-01/config.md" ]
  [ ! -d "$ARTIFACT_DIR/phases/phase-01/.qrspi" ]
  [ ! -d "$ARTIFACT_DIR/phases/phase-01/phases" ]
}

@test "[T16-5] snapshot on non-existent artifact_dir returns non-zero" {
  run artifact_snapshot_phase "/tmp/nonexistent-dir-$RANDOM" 1

  [ "$status" -ne 0 ]
}

@test "[T16-6] artifact_promote_next_phase deletes structure.md, plan.md, tasks/" {
  _t16_setup_artifact_dir

  artifact_promote_next_phase "$ARTIFACT_DIR" 1

  [ ! -f "$ARTIFACT_DIR/structure.md" ]
  [ ! -f "$ARTIFACT_DIR/plan.md" ]
  [ ! -d "$ARTIFACT_DIR/tasks" ]
}

@test "[T16-7] artifact_promote_next_phase resets design.md frontmatter to draft" {
  _t16_setup_artifact_dir

  artifact_promote_next_phase "$ARTIFACT_DIR" 1

  local design_status
  design_status=$(frontmatter_get "$ARTIFACT_DIR/design.md" "status")
  [ "$design_status" = "draft" ]
}

@test "[T16-8] artifact_promote_next_phase leaves goals.md, questions.md, research/summary.md intact" {
  _t16_setup_artifact_dir

  artifact_promote_next_phase "$ARTIFACT_DIR" 1

  [ -f "$ARTIFACT_DIR/goals.md" ]
  [ -f "$ARTIFACT_DIR/questions.md" ]
  [ -f "$ARTIFACT_DIR/research/summary.md" ]

  local goals_status
  goals_status=$(frontmatter_get "$ARTIFACT_DIR/goals.md" "status")
  [ "$goals_status" = "draft" ]
}

@test "[T16-9] artifact_promote_next_phase deletes reviews/, feedback/, .qrspi/" {
  _t16_setup_artifact_dir

  artifact_promote_next_phase "$ARTIFACT_DIR" 1

  [ ! -d "$ARTIFACT_DIR/reviews" ]
  [ ! -d "$ARTIFACT_DIR/feedback" ]
  [ ! -d "$ARTIFACT_DIR/.qrspi" ]
}

@test "[T16-10] snapshot copies parallelization.md when present" {
  _t16_setup_artifact_dir

  artifact_snapshot_phase "$ARTIFACT_DIR" 1

  [ -f "$ARTIFACT_DIR/phases/phase-01/tasks/parallelization.md" ]
}

@test "[T16-11] snapshot with phase 12 creates phases/phase-12/" {
  _t16_setup_artifact_dir

  artifact_snapshot_phase "$ARTIFACT_DIR" 12

  [ -d "$ARTIFACT_DIR/phases/phase-12" ]
  [ -f "$ARTIFACT_DIR/phases/phase-12/goals.md" ]
}

@test "[T16-12] artifact_promote_next_phase on non-existent dir returns non-zero" {
  run artifact_promote_next_phase "/tmp/nonexistent-dir-$RANDOM" 1

  [ "$status" -ne 0 ]
}
