#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  source "$BATS_TEST_DIRNAME/../../hooks/lib/artifact-map.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =============================================================================
# artifact_map_get — forward lookup (step → file)
# =============================================================================

@test "artifact_map_get: goals → goals.md, exit 0" {
  run artifact_map_get "goals"
  [ "$status" -eq 0 ]
  [ "$output" = "goals.md" ]
}

@test "artifact_map_get: questions → questions.md, exit 0" {
  run artifact_map_get "questions"
  [ "$status" -eq 0 ]
  [ "$output" = "questions.md" ]
}

@test "artifact_map_get: research → research/summary.md, exit 0" {
  run artifact_map_get "research"
  [ "$status" -eq 0 ]
  [ "$output" = "research/summary.md" ]
}

@test "artifact_map_get: design → design.md, exit 0" {
  run artifact_map_get "design"
  [ "$status" -eq 0 ]
  [ "$output" = "design.md" ]
}

@test "artifact_map_get: structure → structure.md, exit 0" {
  run artifact_map_get "structure"
  [ "$status" -eq 0 ]
  [ "$output" = "structure.md" ]
}

@test "artifact_map_get: plan → plan.md, exit 0" {
  run artifact_map_get "plan"
  [ "$status" -eq 0 ]
  [ "$output" = "plan.md" ]
}

@test "artifact_map_get: nonexistent → exit 1" {
  run artifact_map_get "nonexistent"
  [ "$status" -eq 1 ]
}

@test "artifact_map_get: empty string → exit 1" {
  run artifact_map_get ""
  [ "$status" -eq 1 ]
}

# =============================================================================
# artifact_map_get_step — reverse lookup (file → step)
# =============================================================================

@test "artifact_map_get_step: goals.md → goals" {
  run artifact_map_get_step "goals.md"
  [ "$status" -eq 0 ]
  [ "$output" = "goals" ]
}

@test "artifact_map_get_step: /some/path/goals.md → goals" {
  run artifact_map_get_step "/some/path/goals.md"
  [ "$status" -eq 0 ]
  [ "$output" = "goals" ]
}

@test "artifact_map_get_step: research/summary.md → research" {
  run artifact_map_get_step "research/summary.md"
  [ "$status" -eq 0 ]
  [ "$output" = "research" ]
}

@test "artifact_map_get_step: /path/to/research/summary.md → research" {
  run artifact_map_get_step "/path/to/research/summary.md"
  [ "$status" -eq 0 ]
  [ "$output" = "research" ]
}

@test "artifact_map_get_step: unknown file → exit 1" {
  run artifact_map_get_step "unknown.md"
  [ "$status" -eq 1 ]
}

# =============================================================================
# No hardcoded step-to-file mappings in consumers
# =============================================================================

@test "no hardcoded step-to-file mappings remain in state.sh" {
  # state.sh should not contain artifact filenames like goals.md, questions.md, etc.
  # (except in source/comment lines)
  local lib_dir="$BATS_TEST_DIRNAME/../../hooks/lib"
  # Check for lines that map steps to files (the pattern we're eliminating)
  local count
  count=$(grep -cE '(goals\.md|questions\.md|research/summary\.md|design\.md|structure\.md|plan\.md)' "$lib_dir/state.sh" || true)
  # Should be zero — all mappings delegated to artifact-map.sh
  [ "$count" -eq 0 ]
}

@test "no hardcoded step-to-file mappings remain in artifact.sh" {
  local lib_dir="$BATS_TEST_DIRNAME/../../hooks/lib"
  # Count lines with artifact filenames (excluding source lines and comments)
  local count
  count=$(grep -E '(goals\.md|questions\.md|research/summary\.md|design\.md|structure\.md|plan\.md)' "$lib_dir/artifact.sh" | grep -cvE '^\s*(#|source )' || true)
  # ARTIFACT_FILES array is allowed (it references artifact_map_get now),
  # but case-statement mappings should be gone.
  # We check specifically for case-pattern lines mapping step→file
  local case_count
  case_count=$(grep -cE '"(goals|questions|research|design|structure|plan)"\)' "$lib_dir/artifact.sh" || true)
  [ "$case_count" -eq 0 ]
}

@test "no hardcoded step-to-file case mappings remain in pipeline.sh" {
  local lib_dir="$BATS_TEST_DIRNAME/../../hooks/lib"
  # _pipeline_get_artifact_file should no longer have a case statement mapping steps to files
  local count
  count=$(grep -cE 'goals\) echo.*goals\.md|questions\) echo.*questions\.md|research\) echo.*research/summary\.md|design\) echo.*design\.md|structure\) echo.*structure\.md|plan\) echo.*plan\.md' "$lib_dir/pipeline.sh" || true)
  [ "$count" -eq 0 ]
}

@test "no hardcoded step-to-file suffix matching in pre-tool-use" {
  local hook_dir="$BATS_TEST_DIRNAME/../../hooks"
  # The old suffix-matching if/elif chain should be replaced with artifact_map_get_step
  local count
  count=$(grep -cE '\*/goals\.md|questions\.md|design\.md|structure\.md|plan\.md|\*/research/summary\.md' "$hook_dir/pre-tool-use" || true)
  [ "$count" -eq 0 ]
}
