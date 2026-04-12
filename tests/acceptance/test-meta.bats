#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 8.
#
# Criterion 8: "All existing pipeline functionality (Goals through Replan)
#   continues to work after Phase 4 changes — validated by the unit tests
#   passing (baseline confirmed)."
#   → Meta-test: confirm the unit test suite still has exactly 218 @test entries
#     across exactly 11 .bats files.
#
# Note: test-validate.bats was deleted in M27 — validation logic was relocated
# to skills/using-qrspi/SKILL.md prose. File count is now 11, test count 218.

# ── Helpers ──────────────────────────────────────────────────────────────────

unit_test_dir() {
  echo "$(dirname "$BATS_TEST_DIRNAME")/unit"
}

# ── Criterion 8: Unit test suite baseline ────────────────────────────────────

# AC8 — The unit test directory contains exactly 11 .bats files
@test "[AC8] Unit test suite has exactly 11 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 11 ]
}

# AC8 — Across all 11 unit test files, there are exactly 218 @test definitions
@test "[AC8] Unit test suite has exactly 218 @test definitions (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 218 ]
}

# AC8 — Every expected unit test file is present by name
@test "[AC8] All 11 expected unit test files are present by name" {
  local dir
  dir="$(unit_test_dir)"

  local expected_files=(
    "test-artifact.bats"
    "test-audit.bats"
    "test-bash-detect.bats"
    "test-enforcement.bats"
    "test-frontmatter.bats"
    "test-pipeline.bats"
    "test-pre-tool-use.bats"
    "test-setup-project-hooks.bats"
    "test-state.bats"
    "test-task.bats"
    "test-worktree.bats"
  )

  for f in "${expected_files[@]}"; do
    [ -f "$dir/$f" ]
  done
}

# AC8 — No unit test file is empty (each has at least one @test)
@test "[AC8] No unit test file is empty (all have at least one @test)" {
  local dir
  dir="$(unit_test_dir)"

  while IFS= read -r bats_file; do
    local test_count
    test_count=$(grep -c "^@test" "$bats_file" || true)
    [ "$test_count" -gt 0 ]
  done < <(find "$dir" -maxdepth 1 -name "*.bats" -type f | sort)
}
