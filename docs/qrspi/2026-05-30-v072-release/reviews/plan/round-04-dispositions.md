# Round 04 dispositions — plan step

**Scope:** broaden round vs `<base-branch>` (full diff = 2406 lines).
**Reviewers:** 14 (7 Claude qrspi-plan-* + 7 Codex code-review).
**Findings:** 8 emitted (6 clean sentinels).
**Verifier:** 8/8 sidecars on disk (no Haiku flakes this round).
**Kept after filter:** 3 (1 correctness-at-floor + 2 scope-bypass).

## Convergent finding

Three reviewers landed on Phase 1 Acceptance Criteria bullet 2 (the universal-quantified "Every fail-loud invariant" claim added in round-03):

- `quality-claude.F01` (correctness, 70 — at floor): bullet's `_resolve-lib.sh` halt phrasing said "against an unknown vendor", which doesn't match T16's actual halt contract (T16 halts on `tier: none` regardless of vendor; "unknown vendor" routes through a different code path).
- `test-coverage-claude.F02` (correctness, 42 — dropped, but convergent with qty-claude.F01): same defect from the Test-phase fixture angle.
- `security-claude.F01` (scope, 62 → kept via scope-bypass): the universal-quantified leading clause enumerates only 6 invariants, leaving T19 `[second-reviewer-unavailable]`, T34 block-hash mismatch, and T02 verifier-fan-in halt causes unenumerated. Plan-altitude regression surface: a refactor of a shared script (`_resolve-lib.sh`, `dispatch-agent.sh`, `round-prepare.sh`) could silently regress an unenumerated invariant.

Combined fix on bullet 2: dropped the "unknown vendor" qualifier AND extended the enumeration with 4 invariants (T19 same-vendor, T19 unavailable, T34 block-hash, T02 fan-in halt causes). Bullet now matches T16's actual halt contract and honors its universal-quantified framing.

## Per-finding dispositions

### KEPT (3)

| ID | Reviewer | CT/Score | Disposition |
|---|---|---|---|
| F01 | quality-claude | correctness/70 | **FIXED.** AC #2 bullet 2 rewritten — `_resolve-lib.sh` halt phrasing matches design.md ## G25 L2090/L2096 verbatim ("when a CD-1 dispatch resolves to a `tier: none` configuration"). |
| F01 | security-claude | scope/62 (bypass) | **FIXED.** AC #2 bullet 2 enumeration extended with 4 release-introduced fail-loud invariants (T19 same-vendor, T19 unavailable, T34 block-hash mismatch, T02 verifier-fan-in halt causes). Universal-quantified leading clause now matches operative bullet list. |
| F01 | silent-failure-claude | scope/68 (bypass) | **FIXED via option 1 (T16 ownership).** Distinctness invariant for primary vs second-reviewer slot reassigned from "dispatch-time code" (which no task owned) to T16's `_resolve-lib.sh` matrix lookup, where it naturally lives (the resolver is the layer that computes the second-reviewer dispatch). Added: T16 DoD bullet (`_resolve-lib.sh` halts with `[second-reviewer-same-vendor]` when same vendor for both slots), T16 test expectation (fixture: same-vendor resolution halts and emits no spec lines), T19 Out rewrite (positive ownership pointer at T16 instead of vague "dispatch-time code"), AC #2 enumeration entry for the new halt. T16's existing target file `tests/unit/test-routing-matrix-application.bats` is the natural home for the new fixture. |

### DROPPED (5)

| ID | Reviewer | CT/Score | Reason |
|---|---|---|---|
| F02 | quality-claude | clarity/60 | Threshold 80. Overview cross-slice chain T13 attribution to `scripts/round-prepare.sh` vs `skills/implement/SKILL.md` — minor clarity nit; sub-threshold. |
| F01 | quality-codex | correctness/45 | Threshold 70. AC #6 "35 goal-backing parent issues all close" vs absorbed G25/G26/G29 dispositions — verifier judged the claim loose enough to interpret; informational/release-management bullet. |
| F01 | security-codex | correctness/28 | Threshold 70. T20 `.dispatch/` artifact leak: missing AC for ignore-rule safeguard — verifier judged this is implementation-hygiene altitude (gitignore convention), not Plan-altitude security gate. |
| F01 | test-coverage-claude | clarity/45 | Threshold 80. T38 mental-replay bullet unverifiable given Scope-Out forbids test-code files — sub-threshold; could be addressed by demoting to rationale text but not load-bearing. |
| F02 | test-coverage-claude | correctness/42 | Threshold 70. Convergent with quality-claude.F01 (AC #2 bullet 2 mis-scope from Test-phase angle); the convergent finding was kept at floor and the bullet was fully rewritten, so this is closed by the same edit. |

## Verifier-filter observations (for v0.7.3 plugin issues)

- Verifier was strict this round: 5 of 8 findings dropped including 2 that name real Plan-altitude defects (qty-codex.F01 AC #6 absorbed-issues, sec-codex.F01 T20 ignore-rule). The "≥70 correctness floor" works as designed but does drop hardening-relevant findings the reviewer judged real. This may merit a v0.7.3 calibration look (lower the correctness floor for "scope" or "scope-adjacent" change_types?).
- Scope-bypass continues to be load-bearing: 2 of 3 kept findings (sec-claude.F01, sf-claude.F01) survived only via the scope-bypass branch. Both were genuine Plan-altitude gaps; both got real fixes. Validates the scope-bypass design choice.
