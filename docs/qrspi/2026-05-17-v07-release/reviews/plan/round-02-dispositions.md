# Plan round-2 dispositions

## Convergence trend
| Round | Findings emitted | Kept after verifier | Notes |
|-------|------------------|---------------------|-------|
| R1    | 46               | 46                  | Codex partial (4 of 7); 0 dropped at verifier |
| R2    | 30 (Claude only) | 22                  | Codex absent (full usage-limit failure); 8 dropped at verifier per round-2 lightweight-task calibration |

## Kept findings (by change_type)

### Auto-apply (correctness)
- quality-claude.R2-F01 — T25-T28 dependencies T-prefix (Group A2; convergent with spec-claude.R2-F01)
- quality-claude.R2-F02 — T20 cross-skill OWNS/DEFERS audit
- spec-claude.R2-F01 — T25-T28 T-prefix (Group A2, convergent)
- spec-claude.R2-F02 — T19 sizing_exception label (reusable primitives → CI scaffolding)
- security-claude.R2-F01 — T03 SSRF carve-out via QRSPI_ALLOW_LOCALHOST_BASE_URL env var; narrow to 127.0.0.0/8
- security-claude.R2-F02 — T27 reference_artifact path-traversal validation
- security-claude.R2-F03 — T07 guard_marker end-to-end through real sourced library
- security-claude.R2-F04 — T14/T19 CI expression-injection hardening (env: pattern)
- silent-failure-claude.R2-F01 — T27/T28/T30 REDACTION-NOTICE entry on wave_context redaction
- silent-failure-claude.R2-F02 — T01 backfill in-memory clarification (no persistent marker)
- silent-failure-claude.R2-F03 — T42 markdown-shape vs phase-acceptance disambiguation
- silent-failure-claude.R2-F04 — T33/T36 run-ID + atomic lock-file for stale-report detection
- silent-failure-claude.R2-F05 — T08 empty-string task_definition fails loudly
- silent-failure-claude.R2-F06 — T31/T32 exact-set verification + duplicate-ID fixture
- silent-failure-claude.R2-F07 — T16 zero workflow-runs fails CI gate
- goal-traceability-claude.R2-F01 — G4 Path B (T43 added as conditional task)
- goal-traceability-claude.R2-F02 — Slice 7 Mechanism B acceptance bullet
- goal-traceability-claude.R2-F03 — Slice 5 quick-tier wording acceptance bullet
- test-coverage-claude.R2-F01 — T10 per-adapter unrecognized-output scenarios (covered alongside scope-claude.R2-F01 rewrite)
- test-coverage-claude.R2-F08 — T36 three-sample / final-section-boundary headings
- scope-claude.R2-F01 — T10 plain-language behavior class rewrite
- scope-claude.R2-F02 — T37 remove regex literal; keep exclusion categories

### Pause for user (intent)
- None this round — all kept findings are correctness clarifications or scope rebalancing.

## Dropped at verifier (score < 70)
- test-coverage-claude.R2-F02 (T16 behavioral test) — T16 is lightweight; doc-shape IS the contract surface for lightweight tasks per round-2 calibration. T19 / phase-acceptance owns behavior.
- test-coverage-claude.R2-F03 (T12 behavioral test) — T12 is lightweight; T13's test-tdd-dispatch-order.bats covers behavior cross-task.
- test-coverage-claude.R2-F04 (T26 behavioral test) — T26 is lightweight; T30 pin five covers behavior.
- test-coverage-claude.R2-F05 (T28 behavioral test) — T28 is lightweight; T30 covers behavior; T28 third bullet already specifies the cross-reference contract.
- test-coverage-claude.R2-F06 (T29 no-blanket-merge enforcement) — T29 is lightweight; finding offers advisory-prose option (2) which matches current spec.
- test-coverage-claude.R2-F07 (T31 N=3 behavioral) — T31 is lightweight; T32 is the dedicated pin task and shares dependencies.
- test-coverage-claude.R2-F09 (T38 cross-ref T39) — T38 is lightweight; T39 owns the behavioral pin.
- test-coverage-claude.R2-F10 (T41 missing-subsection variants) — T41 is lightweight; T42 owns behavioral coverage and can be expanded if needed without expanding T41.

## Codex status
- ALL 7 codex reviewers failed (usage limit). Limit resets ~9:49 PM PT. Optional catch-up codex pass post-limit-reset.

## Round-2-specific decisions
- G4 Path B: applied by adding T43 (conditional task, NO-OP under Path A).
- T20 cross-skill OWNS/DEFERS audit: applied (audit scope expanded; future-goals.md logging path added; DONE-report enumeration required).
- T19 sizing_exception label: changed from `reusable primitives` to `CI scaffolding` to align with the existing rationale.
- Documentation-shape test expectations for lightweight tasks: dropped 8 test-coverage-claude findings per round-2-specific calibration; lightweight task contract IS prose-content verification, cross-task pins (T13/T30/T32/T39/T42) carry behavioral coverage.
- security-claude.R2-F03 (guard_marker end-to-end) and test-coverage-claude.R2-F01 (per-adapter unrecognized) are folded into adjacent fixes (T07 pin and scope-claude.R2-F01 T10 rewrite respectively) to avoid duplicated edits.

## Next step
- Round 3 review after fixes applied.
- Optional: catch-up codex pass post-limit-reset.
