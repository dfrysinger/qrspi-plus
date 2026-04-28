#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 8.
#
# Criterion 8: "All existing pipeline functionality (Goals through Replan)
#   continues to work after Phase 4 changes — validated by the unit tests
#   passing (baseline confirmed)."
#   → Meta-test: confirm the unit test suite still has the documented
#     @test/.bats baseline (post-Wave-6 octopus T16+T17 merge).
#
# Phase 4 changes: test-validate.bats deleted (M27), test-artifact-map.bats
# added (U8). Initial 12 .bats / 287 @tests baseline.
# Wave 6 (2026-04-27) adds cross-cutting tests across T16/T17/T18:
#   T16: +1 unit .bats (test-change-type-classification.bats), +5 augmenting
#        @tests in test-reviewer-boilerplate-embed.bats, +1 acceptance
#        (test-review-pause.bats — not counted by this baseline). Plus
#        T16 fix-cycle 1 +3 contrast tests.
#   T17: +4 unit .bats (test-skill-md-content-patterns.bats,
#        test-scope-reviewer.bats, test-scope-reviewer-parallel-with-claude.bats,
#        test-scope-reviewer-rules-loading.bats), +1 acceptance
#        (test-skill-output-quality.bats — not counted).
#   T18: +2 unit .bats (test-u14-lint.bats, test-compaction-emphasis-markup.bats).

# ── Helpers ──────────────────────────────────────────────────────────────────

unit_test_dir() {
  echo "$(dirname "$BATS_TEST_DIRNAME")/unit"
}

# ── Criterion 8: Unit test suite baseline ────────────────────────────────────

# AC8 — The unit test directory contains exactly 23 .bats files
@test "[AC8] Unit test suite has exactly 23 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 23 ]
}

# AC8 — Unit test count baseline (updated 2026-04-27, T16+T17 octopus)
@test "[AC8] Unit test suite has exactly 509 @test definitions (baseline)" {
  # Baseline updated for stage-after-G6 octopus merge of T16 + T17.
  # T16 deltas (over 416): +17 from test-change-type-classification.bats
  #   (5 change_type tags + secondary-escalation + pause-gate dispatch +
  #   10-round cap-counter PAUSE_PENDING contract); +5 from
  #   test-reviewer-boilerplate-embed.bats augmentation (M48 cross-cutting
  #   embed-coverage: 14 distinct files, drift detection, missed-sweep
  #   detection, exact full-path occurrence count for test/SKILL.md, all-
  #   three-required-headings); +3 from T16 fix-cycle 1 contrast tests
  #   (apply/skip/loop-back each asserting loop_state=`next` AND cap-
  #   decrement). T16 net +25.
  # T17 deltas (over 416): +26 test-skill-md-content-patterns.bats
  #   (M49-M52 SKILL.md content patterns), +16 test-scope-reviewer.bats
  #   (per-{ARTIFACT_TYPE} dispatch), +13 test-scope-reviewer-parallel-
  #   with-claude.bats, +13 test-scope-reviewer-rules-loading.bats
  #   (1 skipped pending FU-5). T17 net +68.
  # Combined T16+T17 over 416: +25 +68 = +93. 416 → 509.
  # Prior 416 baseline was after 2026-04-27 prompt-improvements T14 fix-cycle 2
  # (+1 for scope-reviewer-allowed-values assertion in
  # test-replan-archive-and-populate.bats — verifies the scope-reviewer
  # template's `## Parameters` allowed-values list includes `replan`). 415 → 416.
  # Prior 415 / 401 / 387 / 381 / 362 / 307 / 301 / 299 / 283 baselines see git log.
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 509 ]
}

# AC8 — Every expected unit test file is present by name (updated 2026-04-27 T16+T17)
@test "[AC8] All 23 expected unit test files are present by name" {
  local dir
  dir="$(unit_test_dir)"

  local expected_files=(
    "test-agent.bats"
    "test-artifact-map.bats"
    "test-artifact.bats"
    "test-audit.bats"
    "test-bash-detect.bats"
    "test-change-type-classification.bats"
    "test-codex-companion-bg.bats"
    "test-frontmatter.bats"
    "test-phasing-four-artifact-pruning.bats"
    "test-phasing-goal-id-consistency.bats"
    "test-phasing-roadmap-generation.bats"
    "test-pipeline.bats"
    "test-pre-tool-use.bats"
    "test-replan-archive-and-populate.bats"
    "test-reviewer-boilerplate-embed.bats"
    "test-scope-reviewer.bats"
    "test-scope-reviewer-parallel-with-claude.bats"
    "test-scope-reviewer-rules-loading.bats"
    "test-setup-project-hooks.bats"
    "test-skill-md-content-patterns.bats"
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
