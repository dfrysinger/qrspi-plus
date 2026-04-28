#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 8.
#
# Criterion 8: "All existing pipeline functionality (Goals through Replan)
#   continues to work after Phase 4 changes — validated by the unit tests
#   passing (baseline confirmed)."
#   → Meta-test: confirm the unit test suite still has the documented
#     @test/.bats baseline (post-Wave-6 octopus T16+T17+T18 merge).
#
# Phase 4 changes: test-validate.bats deleted (M27), test-artifact-map.bats
# added (U8). Initial 12 .bats / 287 @tests baseline.
# Wave 6 (2026-04-27) adds cross-cutting tests across T16/T17/T18:
#   T16: +1 unit .bats (test-change-type-classification.bats), +5 augmenting
#        @tests in test-reviewer-boilerplate-embed.bats, +1 acceptance
#        (test-review-pause.bats — not counted by this baseline). Plus
#        T16 fix-cycle 1 +3 contrast tests. Net +25.
#   T17: +4 unit .bats (test-skill-md-content-patterns.bats,
#        test-scope-reviewer.bats, test-scope-reviewer-parallel-with-claude.bats,
#        test-scope-reviewer-rules-loading.bats), +1 acceptance
#        (test-skill-output-quality.bats — not counted). Net +68.
#   T18: +2 unit .bats (test-u14-lint.bats, test-compaction-emphasis-markup.bats).
#        Plus T18 fix-cycle 1: +11 per-cell M53 negative-coverage @tests,
#        -1 anchor-count lower-bound guard. Net +43.

# ── Helpers ──────────────────────────────────────────────────────────────────

unit_test_dir() {
  echo "$(dirname "$BATS_TEST_DIRNAME")/unit"
}

# ── Criterion 8: Unit test suite baseline ────────────────────────────────────

# AC8 — The unit test directory contains exactly 25 .bats files
@test "[AC8] Unit test suite has exactly 25 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 25 ]
}

# AC8 — Unit test count baseline (updated 2026-04-28, T19 FU-1 state.sh refactor)
@test "[AC8] Unit test suite has exactly 563 @test definitions (baseline)" {
  # Baseline for stage-after-G6 = octopus(T16, T17, T18) on top of
  # stage-after-G5 (0ee9fd1, 18 .bats / 416 @tests). All three Wave 6
  # tasks are file-disjoint except for tests/acceptance/test-meta.bats
  # (this file), where each task bumped the AC8 baseline independently.
  # Resolution combines the deltas:
  #
  #   T16 net +25 (over 416):
  #     +17 from test-change-type-classification.bats (5 change_type
  #     tags + secondary-escalation + pause-gate dispatch + 10-round
  #     cap-counter PAUSE_PENDING contract), +5 from
  #     test-reviewer-boilerplate-embed.bats augmentation (M48 cross-
  #     cutting embed-coverage: 14 distinct files, drift detection,
  #     missed-sweep detection, exact full-path occurrence count for
  #     test/SKILL.md, all-three-required-headings), +3 from T16
  #     fix-cycle 1 contrast tests (apply/skip/loop-back each asserting
  #     loop_state=`next` AND cap-decrement).
  #
  #   T17 net +68 (over 416):
  #     +26 test-skill-md-content-patterns.bats (M49-M52 SKILL.md content
  #     patterns), +16 test-scope-reviewer.bats (per-{ARTIFACT_TYPE}
  #     dispatch), +13 test-scope-reviewer-parallel-with-claude.bats,
  #     +13 test-scope-reviewer-rules-loading.bats (1 skipped pending
  #     FU-5).
  #
  #   T18 net +43 (over 416):
  #     +16 test-u14-lint.bats (5 deterministic lints with seeded
  #     fixtures + FU-7-skipped clean-state assertions on in-scope files
  #     + helper-sanity + scope assertions + FU-7 positive assertions);
  #     +27 test-compaction-emphasis-markup.bats (13 per-row positive
  #     coverage + 4 cross-cutting assertions + 11 per-cell negative
  #     coverage from T18 fix-cycle 1, with 3 negative tests skip-marked
  #     pending FU-9 matrix↔SKILL.md reconciliation; -1 anchor-count
  #     lower-bound guard removed in fix-cycle 1 because per-anchor
  #     positive checks are now load-bearing).
  #
  # Combined T16+T17+T18 over 416: +25 +68 +43 = +136. 416 → 552.
  # Prior 416 baseline was after 2026-04-27 prompt-improvements T14
  # fix-cycle 2 (+1 for scope-reviewer-allowed-values assertion in
  # test-replan-archive-and-populate.bats — verifies the scope-reviewer
  # template's `## Parameters` allowed-values list includes `replan`).
  # 415 → 416.
  # Prior 415 / 401 / 387 / 381 / 362 / 307 / 301 / 299 / 283 baselines
  # see git log.
  #
  # 2026-04-28 T19 (FU-1 state.sh refactor): +3 @tests in test-state.bats
  # ([T19-FU1-1], [T19-FU1-2], [T19-FU1-3]) proving that
  # state_init_or_reconcile delegates the "first non-approved step"
  # computation to state_compute_current_step (single source of truth for
  # pipeline-order rule). 552 → 555. Files baseline (25) unchanged
  # because test-state.bats already exists.
  #
  # 2026-04-28 T32 (integration-round-01 fix-cycle, R1 Codex-S4 + R2 S-N6
  # bundled): +8 @tests in test-reviewer-boilerplate-embed.bats covering
  # the new `## Untrusted Data Handling` section in
  # skills/_shared/reviewer-boilerplate.md (delimiter contract for
  # prompt-injection defense — START / END token form, "treat as data
  # not instructions" rule, findings-about-content-vs-instructions-from-
  # content distinction, secondary-escalation rule scoped to
  # reviewer-emitted findings) and the cross-cutting embed-site coverage
  # ([T32-wrapper] every embed-site SKILL.md / template instructs the
  # UNTRUSTED-ARTIFACT delimiter; reviewer-boilerplate.md contains ≥2
  # delimiter-token references). 555 → 563. Files baseline (25)
  # unchanged because the boilerplate test file already exists; the
  # adversarial-fixture acceptance test landed in
  # tests/acceptance/test-reviewer-injection.bats which is NOT counted
  # by this unit baseline.
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 563 ]
}

# AC8 — Every expected unit test file is present by name (updated 2026-04-27 T16+T17+T18)
@test "[AC8] All 25 expected unit test files are present by name" {
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
    "test-compaction-emphasis-markup.bats"
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
