# Round 01 dispositions

## Applied (kept findings)

1. **quality-claude.R1-F01** (correctness, 90) — Added `skills/_shared/evergreen-output-rule.md` Create row to Slice 1.5. Cited CD-2. All nine consumer Modify rows already present; no new consumer rows needed.
2. **quality-claude.R1-F02** (correctness, 85) — Added `skills/_shared/multi-actor-flow-check.md` Create row to Slice 1.5. Cited CD-3. All four consumer Modify rows already present; no new consumer rows needed.
3. **quality-claude.R1-F03** / **quality-codex.R1-F01** (correctness, 85/82 — convergent pair) — Added `skills/_shared/verifier-dispatch-prose.md` Create row to Slice 1.1. Cited G12. Both consumer Modify rows (`using-qrspi/SKILL.md`, `implement/SKILL.md`) already present.
4. **quality-claude.R1-F04** / **quality-codex.R1-F03** (correctness, 85/80 — convergent pair) — Added `scripts/detect-interaction-mode.sh` Create row to Slice 1.4. Added Interface §13 with full CD-4 §I.7 contract (output shapes, exit codes, platform directory summary, audit-log file shape `<round-dir>/.interaction-mode-audit.json`). Audit file folded into §13 rather than a separate file-map row.
5. **quality-claude.R1-F05** (correctness, 80) — Changed Slice 1.2 `scripts/dispatch-agent.sh` action from Create to Modify. Updated responsibility description to reflect additive observability work. Slice 1.4 Create row unchanged.
6. **quality-claude.R1-F06** (correctness, 82) — Changed Slice 1.3 `scripts/round-prepare.sh` action from Create to Modify. Updated responsibility description to reflect additive per-task diff/scope/commit-anchor work. Slice 1.4 Create row unchanged.
7. **quality-codex.R1-F02** (correctness, 78) — Added `tests/lint/test-design-altitude-boundary-include.bats` Create row to Slice 1.5. Cited G34. Sibling `test-structure-altitude-boundary-include.bats` in Slice 1.6 confirmed consistent.
8. **quality-codex.R1-F04** (correctness, 82) — Renamed all `fan-in-audit.json` occurrences to `.verifier-fan-in-audit.json`: Interface §1 script contract (stdout line) and Interface §11 heading. Interface §13 uses the correct dotfile name throughout.
9. **scope-claude.R1-F01** (scope, medium) — Collapsed Interface §12 to placeholder pattern matching Interfaces §5/§6: replaced actual threshold sentences with `<threshold and filter rule prose>` and `- ...` placeholder. Concrete path callout retained.
10. **scope-claude.R1-F02** / **scope-codex.R1-F01** (scope, medium — convergent pair) — Added `## Section Contracts` section after `## Test Architecture`. Covers all 16 new `skills/` and `_shared/` files created in this release at heading-level granularity. Files already contracted in Interfaces §5/§6/§12/§13 are cross-referenced.
11. **scope-codex.R1-F02** (scope, medium) — Added `## Hook-Point Locations` section after `## Section Contracts`. Enumerates cross-cutting `!cat` include sites for CD-1 (12 skills), CD-2 (9 skills), CD-3 (4 skills), CD-4/G12 (2 skills), G34 (2 consumers), and G35 (2 consumers) at file + section heading granularity.

## Dropped (verifier-filtered or pause-gate-skipped)

- **quality-claude.R1-F07** (clarity, per score file) — Reviewed score file; finding did not reach the correctness/scope threshold for auto-apply. No action taken.
- **scope-codex.R1-F03** (scope) — Score file indicates verifier ruled this a false positive or below threshold; not in the 10 kept findings listed in the task brief.

## Notes

- Pause-gate scope findings (scope-claude.F01, scope-claude.F02, scope-codex.F01, scope-codex.F02) auto-applied under "loop till clean" + autopilot per QRSPI standing directive. Each is a valid OWNS gap: pre-authored boundary prose in Interface §12, missing section-list contracts, missing hook-point locations.
- Convergent cross-family evidence on 4 issues: verifier-dispatch-prose.md missing (claude+codex), detect-interaction-mode.sh missing (claude+codex), section-list contracts missing (claude+codex), Interface §12 pre-authored prose (claude+codex).
- File-map row counts: 5 rows added (Create), 2 rows changed (Create→Modify). Interface count: +1 (§13). Sections added: 2 (Section Contracts, Hook-Point Locations).
- design.md CD-4 §I.7 (lines 600–693) consulted for Interface §13 contract. design.md G34 D5 and G35 D5 consulted for hook-point location placements. design.md lines 286, 335–345 consulted for CD-2/CD-3 consumer placement guidance.
