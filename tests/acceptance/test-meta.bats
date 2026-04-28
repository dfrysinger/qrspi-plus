#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 8.
#
# Criterion 8: "All existing pipeline functionality (Goals through Replan)
#   continues to work after Phase 4 changes — validated by the unit tests
#   passing (baseline confirmed)."
#   → Meta-test: confirm the unit test suite still has exactly 287 @test entries
#     across exactly 12 .bats files.
#
# Phase 4 changes: test-validate.bats deleted (M27), test-artifact-map.bats
# added (U8). File count stays at 12, test count updated to 287.

# ── Helpers ──────────────────────────────────────────────────────────────────

unit_test_dir() {
  echo "$(dirname "$BATS_TEST_DIRNAME")/unit"
}

# ── Criterion 8: Unit test suite baseline ────────────────────────────────────

# AC8 — The unit test directory contains exactly 20 .bats files
@test "[AC8] Unit test suite has exactly 20 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 20 ]
}

# AC8 — Unit test count baseline (updated 2026-04-27 T18)
@test "[AC8] Unit test suite has exactly 449 @test definitions (baseline)" {
  # Baseline updated after 2026-04-27 prompt-improvements T18 (U14 lint +
  # M53 emphasis tests + 5 violation fixtures). +33 over 416:
  # +16 in test-u14-lint.bats (5 deterministic lints with positive coverage
  # on seeded fixtures and FU-7-skipped clean-state assertions on in-scope
  # files; 2 helper-sanity tests; 2 scope assertions; 2 FU-7 positive
  # assertions confirming the lint catches pre-existing in-scope
  # violations) and +17 in test-compaction-emphasis-markup.bats (13 per-row
  # M53 matrix coverage tests across the 13-row matrix + 4 cross-cutting
  # assertions: no shared callout file, no shared callout citation,
  # per-task-orchestrator delegation contract, anchor-count lower-bound
  # mutation guard). 416 → 449.
  # Baseline 416 set after 2026-04-27 prompt-improvements T14 fix-cycle 2
  # (+1 for scope-reviewer-allowed-values assertion in
  # test-replan-archive-and-populate.bats — verifies the scope-reviewer
  # template's `## Parameters` allowed-values list includes `replan`, which
  # guards the CodexF1 silent-failure mode where the template would fail-closed
  # before running checks). 415 → 416.
  # Prior 415 baseline was after 2026-04-27 prompt-improvements T14 Round-1 FIX
  # (+14 fail-closed tests in test-replan-archive-and-populate.bats covering
  # the 5-step ABORT clauses (10 tests: 2 per step) and the scope-reviewer
  # dispatch in the Review Round (4 tests: dispatch presence + ARTIFACT_TYPE,
  # OWNS/DEFERS co-occurrence, fail-closed-on-malformed, parallel-with-Claude).
  # 401 → 415.
  # Prior 401 baseline was after 2026-04-27 prompt-improvements T14 initial
  # author (+14 tests in the new test-replan-archive-and-populate.bats file,
  # covering OWNS/DEFERS heading + H3 sub-blocks, the five-step archive-and-
  # populate sequence, status-draft marking, qrspi:goals invocation, and
  # future-research naming normalization). 387 → 401.
  # Prior 387 baseline was after T5 Round-1 FIX
  # (+6 mutation-resistant + fail-closed tests across the 3 phasing files).
  # T5 Round-1 FIX added: scope-reviewer fail-closed (+1, roadmap-generation),
  # orphan emission round-invalid (+1, goal-id-consistency), reviewer-reject
  # missing Orphan IDs (+1, goal-id-consistency), 8-target enumeration (+1,
  # four-artifact-pruning), pruning atomicity (+1, four-artifact-pruning),
  # synthesis atomicity (+1, four-artifact-pruning). 381 → 387.
  # Prior 381 baseline was after T5 initial author (added 3 new bats files,
  # +19 tests): test-phasing-roadmap-generation (+5), test-phasing-goal-id-
  # consistency (+5), test-phasing-four-artifact-pruning (+9). 362 → 381.
  # Prior 362 baseline was after Wave 1 + Wave 2 merge (T1 +25, T3 +30, T4
  # +6 over 307 — sums to 362; T2/T11 are markdown-only).
  # Prior 307 baseline was after T4 Round-4 thoroughness FIX (+6 boundary
  # tests). Prior 301/299/283 baselines see git log.
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 449 ]
}

# AC8 — Every expected unit test file is present by name (updated 2026-04-27 T18)
# T18 adds test-u14-lint.bats and test-compaction-emphasis-markup.bats (M53)
@test "[AC8] All 20 expected unit test files are present by name" {
  local dir
  dir="$(unit_test_dir)"

  local expected_files=(
    "test-agent.bats"
    "test-artifact-map.bats"
    "test-artifact.bats"
    "test-audit.bats"
    "test-bash-detect.bats"
    "test-codex-companion-bg.bats"
    "test-compaction-emphasis-markup.bats"
    "test-frontmatter.bats"
    "test-phasing-four-artifact-pruning.bats"
    "test-phasing-goal-id-consistency.bats"
    "test-phasing-roadmap-generation.bats"
    "test-pipeline.bats"
    "test-pre-tool-use.bats"
    "test-replan-archive-and-populate.bats"
    "test-reviewer-boilerplate-embed.bats"
    "test-setup-project-hooks.bats"
    "test-state.bats"
    "test-task.bats"
    "test-u14-lint.bats"
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
