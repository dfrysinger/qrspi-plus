---
artifact: structure
round: 7
ref: 2c66e44 (R5 commit — narrow round per convergence rule, R6 was broaden)
diff_lines: 99
reviewers_dispatched: 5 (quality-claude, quality-codex, scope-claude, scope-codex, stitching-audit)
findings_total: 7
findings_kept: 5
findings_dropped: 2
---

# Structure Round 07 — Verified Findings

## Reviewer Outcomes

| Reviewer | Result | Notes |
|---|---|---|
| scope-claude | clean | matches CD-1…G35 precedent on G31 row |
| quality-codex | clean (NO_FINDINGS) | hand-persisted sentinel from chat-only |
| scope-codex | 1 scope finding (F01 medium) | bypass-verifier; hand-persisted from chat-only |
| quality-claude | 3 findings (F01 high, F02 med, F03 low) | wrote to disk |
| stitching-audit | 3 findings (F01 med, F02 high, F03 med) | wrote to disk |

## Verifier Scores + Disposition

| Finding | Sev | Type | Score | Floor | Disposition |
|---|---|---|---|---|---|
| qc-F01 — G31 Consumer #9 (plan-test-coverage-reviewer / Addition C) missing | high | correctness | 85 | 70 | **KEEP** |
| qc-F02 — G31 Hook-Point materially incomplete (Consumer #1, wrappers, reviewer-addition uncovered) | medium | correctness | 75 | 70 | **KEEP** |
| qc-F03 — Rename convention inconsistency (4 R6 rows vs. pre-existing launch-await-pattern row) | low | style | 80 | 80 | **KEEP** (at floor) |
| sa-F01 — Stale test names (test-run-codex-review.bats, test-codex-review-codex-availability.bats) | medium | correctness | 70 | 70 | **KEEP** (at floor) |
| sa-F02 — qrspi-plan-test-coverage-reviewer.md needs G31 Addition C row (SAME as qc-F01) | high | correctness | 88 | 70 | **KEEP** (independent corroboration) |
| sa-F03 — §10 host/vendor not pinned by a test row | medium | correctness | 38 | 70 | **DROP** (well below floor) |
| scope-codex F01 — Hook-Point "Addition B verbatim" content leak | medium | scope | bypass | — | **DROP** (orchestrator judgment — see rationale below) |

Kept 5 of 7 verified + 0 of 1 scope-bypass = 5 kept overall.

## scope-codex F01 — Drop Rationale (Documented)

The dedicated scope reviewer (scope-claude) returned clean and explicitly cited "matches CD-1…G35 precedent" for the G31 Hook-Point row. The G35 row at line 757 carries a similar content-leaning phrase: "immediately after Step 1 Read citation (introducer prose precedes the include)" — that is positional + content guidance, not pure location metadata. The G31 row's "+ Addition B verbatim" is the same kind of guidance (naming the additional named-content block that accompanies the `!cat`). Two reasoned signals (scope-claude clean + G35 precedent) outweigh the lone over-conservative scope-codex finding. Documented in dispositions for traceability.

## Convergence Trend

| Round | Findings | Kept |
|---|---|---|
| R3 | 12 | 8 |
| R4 | 8 | 4 |
| R5 | 5 | 2 |
| R6 (broaden) | 6 | 5 |
| **R7 (narrow)** | **7** | **5** |

R7 ≈ R6 not because R6 was incomplete in coverage — but because R6's stitching-audit sa-F01 finding ("G31 integration footprint incomplete") was itself incompletely scoped (named 3 of 6 agents + 1 of multiple `!cat` sites). R7 narrow uncovered the remaining G31 surface: Consumer #1 (plan classifier), Consumer #9 (plan-test-coverage-reviewer), wrapper SKILLs (prompt-prose-writer/SKILL.md, prompt-prose-reviewer/SKILL.md), and prompt-prose-reviewer-addition.md hook coverage.

## G31 Distribution Table — Full Inventory (per design.md L2614-2629)

For fix-r7 reference:

| # | Consumer | Mechanism | Currently Mapped? |
|---|---|---|---|
| 1 | `skills/plan/SKILL.md` § Per-Task Classification | Addition A + inline detection `!cat` | Slice 1.5 row exists w/G31; Hook-Point ABSENT |
| 2 | `skills/plan/SKILL.md` writer-subagent dispatch (2 sites) | detection + writer-addition + Addition B | Slice 1.5 row exists w/G31; Hook-Point PRESENT |
| 3 | `skills/design/SKILL.md` authoring step | detection + writer-addition | Slice 1.5 row +G31 (R6); Hook-Point PRESENT |
| 4 | `agents/qrspi-implementer-lightweight.md` | `skills:` preload (prompt-prose-writer) | Slice 1.5 row +G31 (R6) |
| 5 | `agents/qrspi-code-quality-reviewer.md` | `skills:` preload (prompt-prose-reviewer) | Slice 1.4 row +G31 (R6) |
| 6 | `agents/qrspi-design-reviewer.md` | `skills:` preload + Addition D inline | Slice 1.5 row w/G31; Addition D site NOT in Hook-Point |
| 7 | `agents/qrspi-plan-reviewer.md` | `skills:` preload | Slice 1.5 row w/G31 |
| 8 | `agents/qrspi-plan-spec-reviewer.md` | `skills:` preload | Slice 1.5 row +G31 (R6) |
| 9 | `agents/qrspi-plan-test-coverage-reviewer.md` | Addition C inline ONLY (no wrapper preload) | **MISSING from File Map** |

## Dropped Findings — Tracking

- **sa-F03 (38)** — §10 manifest schema test coverage. Verifier judged this Plan-altitude (test authoring is Plan's surface, not Structure's; structure pins test FILES that exist, not the assertions within). Won't resurface in R8 narrow against R7 fix.
- **scope-codex F01 (bypass / orchestrator judgment)** — see rationale above.

## Codex Chat-Only Transport (continuing #288 tracking)

- quality-codex: NO_FINDINGS sentinel hand-persisted
- scope-codex: 1 finding hand-persisted
- Pattern stable across R3-R7; v0.7.3 fix tracked in #288
