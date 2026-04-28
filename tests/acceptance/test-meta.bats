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

# AC8 — The unit test directory contains exactly 29 .bats files
@test "[AC8] Unit test suite has exactly 29 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 29 ]
}

# AC8 — Unit test count baseline (updated 2026-04-28, integration-round-04 round-03-fix-cycle merge)
@test "[AC8] Unit test suite has exactly 773 @test definitions (baseline)" {
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
  # 2026-04-28 integration-round-01 fix-cycle merge: 16 fix tasks
  # converged on the feature branch. Net unit-test additions per task
  # (only those adding @tests in tests/unit/ are listed):
  #   T25 (+17) — repo-root .qrspi/ + parallelization.md gating + worktree slug
  #   T26  (+9) — artifact.sh M54 cascade + sed portability
  #   T27 (+43) — bash-detect.sh coverage gaps + integration sweep
  #   T28  (+3) — audit.sh worktree-CWD fallback (state.json resolver)
  #   T29  (+6) — codex-companion-bg.sh CRIT audit lockdown
  #   T32 (+18) — reviewer-boilerplate untrusted-data wrapper +
  #              embed-site coverage (boilerplate-embed.bats expanded)
  #   T35  (+6) — phasing CRITICAL→high + codex_reviews validation
  #   T38  (+3) — scope-reviewer 6→7 (replan parameterization catch-up)
  #   T39  (+8) — 4-skill phasing.md required-input + new
  #              test-artifact-gating.bats
  # Total fix-cycle delta (13 leaves): +116 over the 555 baseline.
  # 555 → 671.
  #
  # 2026-04-28 integration-round-03 task-33 merge: task-33 brings task-24
  # (state.sh hardening) and task-30 (SessionStart contract) transitively
  # via stage-after-fix-G1, plus task-33's own test-using-qrspi.bats.
  # Per-file delta over the 671 baseline:
  #   T24 (+16) — test-state.bats hardening tests: T24-A1/A1b/A1c/A2/A3/A4
  #              (current_step allowlist), T24-B1..B4 (phase_start_commit
  #              preservation), T24-C1/C1b/C1c/C2/C3 (concurrent locking,
  #              TOCTOU serialization), T24-Sec1 (lock symlink refusal,
  #              skip on non-flock hosts).
  #   T30  (+9) — test-session-start.bats new file (SessionStart
  #              additionalContext contract: hook injects using-qrspi
  #              content, read-only w.r.t. state, no .qrspi/ writes).
  #   T33 (+11) — test-using-qrspi.bats new file (current_step 12-value
  #              enum docs, SessionStart bullet contract verification,
  #              cross-reference test asserting documented values match
  #              state.sh allowlist, audit-naming reconciliation).
  # Total task-33 lineage delta: +36 over 671 baseline. 671 → 707.
  # Files baseline bumped 25 → 29: task-37 added test-structure.bats,
  # task-39 added test-artifact-gating.bats, task-30 added
  # test-session-start.bats, task-33 added test-using-qrspi.bats.
  #
  # 2026-04-28 integration-round-04 round-02-fix-cycle merge: 6 fix tasks
  # (40-45) addressing the 2 MAJOR + 4 MEDIUM round-3 review residuals
  # plus 3 LOW incidentals (L-int-1, L-sec-2, L-sec-3). Per-task delta:
  #   T40 (+2)  — replan SKILL.md snapshot-path read (M-1/F-1)
  #   T41 (+3)  — using-qrspi validator-table + Plan SessionStart drift
  #              regression tests (M-2 + M-3)
  #   T42 (+7)  — state_update --arg/--argjson API extension + race
  #              tests for artifact_sync_state and pipeline_cascade_reset
  #              (S-1 / S-N4 residual)
  #   T43 (+26) — bash-detect cd-before-relative-write coverage (12 pos
  #              + 4 neg + 1 multi-cd in test-bash-detect.bats; 9 in
  #              test-pre-tool-use.bats: 4 subagent block + 1 cd-into-
  #              subdir allow + 2 Write/Edit absolute-path locks + 1
  #              L-sec-3 doc presence + 1 multi-cd block) — S-2 + L-sec-3
  #   T44 (+5)  — audit.sh symlink refusal + find_repo_root CWE-59
  #              hardening (S-3 + L-sec-2)
  #   T45 (+0)  — T04-PHASING-6S rename + assertion (no count change;
  #              same test, additional positive substring match) — L-int-1
  # Total round-02-fix-cycle delta: +43 over 707 baseline. 707 → 749
  # (one test consolidated during T42 implementation rather than added).
  # Files baseline (29) unchanged — all round-02 changes are
  # modifications, no new .bats files.
  #
  # 2026-04-28 integration-round-04 round-03-fix-cycle merge: 2 fix tasks
  # (46-47) addressing the round-4 review's 1 MAJOR + 1 MEDIUM residuals
  # (M4-1 + M4-2). Per durable direction (major/medium only), 3 LOWs
  # (L4-1, L4-2, L4-3) deferred to follow-ups. Per-task delta:
  #   T46 (+21) — broaden cd-escape detection in bash-detect.sh (M4-1 /
  #              S-2 residual). +16 in test-bash-detect.bats (13 negative
  #              cases for variable expansion / command substitution /
  #              pushd / popd / subshell+brace-group wrap / backgrounded
  #              subshell / assignment+var, + 3 positive regression cases
  #              for cd src, cd subdir/nested, cd .) + 5 in
  #              test-pre-tool-use.bats (4 subagent-block regression: cd
  #              "$HOME", cd "$(mktemp -d)", pushd /tmp, (cd /tmp; ...);
  #              + 1 negative cd src allow).
  #   T47 (+3)  — sentinel-aware audit_log_event (M4-2). +3 in
  #              test-audit.bats: __OPAQUE_WRITE__ preserved verbatim in
  #              canonical-path audit row, __OPAQUE_WRITE__ preserved
  #              verbatim in orphan-path audit row, regression check that
  #              ordinary relative target still gets PWD-prepend.
  # Total round-03-fix-cycle delta: +24 over 749. 749 → 773. Files
  # baseline (29) unchanged — all round-03 changes are modifications.
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 773 ]
}

# AC8 — Every expected unit test file is present by name (updated 2026-04-28 round-3 task-33 merge)
@test "[AC8] All 29 expected unit test files are present by name" {
  local dir
  dir="$(unit_test_dir)"

  local expected_files=(
    "test-agent.bats"
    "test-artifact-gating.bats"
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
    "test-session-start.bats"
    "test-setup-project-hooks.bats"
    "test-skill-md-content-patterns.bats"
    "test-state.bats"
    "test-structure.bats"
    "test-task.bats"
    "test-u14-lint.bats"
    "test-using-qrspi.bats"
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
