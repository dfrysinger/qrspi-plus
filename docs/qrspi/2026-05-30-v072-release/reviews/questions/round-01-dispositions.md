# Round 1 Dispositions — questions.md

## Reviewer outputs (R1)

| Reviewer | Findings | Notes |
|---|---|---|
| quality-claude (sonnet-4.6) | 7 findings (F01-F07) | Wrote to disk |
| quality-codex (gpt-5.3-codex) | 2 findings (F01-F02) | Chat-only fallback (PI-002); orchestrator persisted |

Total: 9 findings.

## Verifier scores

| Finding | change_type | Score | Apply-fix decision |
|---|---|---|---|
| quality-claude.R1-F01 (Q16 G19 cite-check leak) | clarity | 75 | DROP (<80) — *applied opportunistically* |
| quality-claude.R1-F02 (Q18 G10 contradiction-refusal leak) | clarity | 70 | DROP (<80) — *applied opportunistically* |
| quality-claude.R1-F03 (G4 + G5 missing) | scope | 85 | KEEP |
| quality-claude.R1-F04 (G13 enum enforcement not covered) | scope | 35 | KEEP (scope always kept) |
| quality-claude.R1-F05 (G18 plan downstream-consumer not covered) | scope | 75 | KEEP |
| quality-claude.R1-F06 (G25 per-H4 pattern not covered) | scope | 75 | KEEP |
| quality-claude.R1-F07 (Q7 "bidirectionally referenced" telegraph) | clarity | 68 | DROP (<80) — *applied opportunistically* |
| quality-codex.R1-F01 (broad goal leakage) | clarity | 75 | DROP (<80) — *applied via per-question rewrites* |
| quality-codex.R1-F02 (coverage gaps G4/G5/G13/G20/G24/G25) | scope | 82 | KEEP |

## Convergent-evidence decision

Four clarity findings (F01 Q16, F02 Q18, F07 Q7, codex-F01 broad) individually scored 68-75 — each below the clarity ≥80 threshold and therefore DROP per the apply-fix protocol. However, they are convergent evidence of the same defect class (goal leakage) and the fixes are cheap. Applied them opportunistically to honor the underlying Iron Law that Questions must not leak goals or intent.

Documented this exception in the dispositions so the next reviewer round can see what changed and why.

## Edits applied to questions.md

1. **Q7** — Stripped "bidirectionally referenced" telegraph; broadened to ask about the prose pattern shared across the four fail-loud paragraphs and whether any class-level invariant exists above them. Addresses quality-claude.R1-F06 (G25 coverage) + quality-claude.R1-F07 (Q7 telegraph).
2. **Q9** — Reframed shebang/warning question as "capture the full stderr output" rather than "does the suite produce deprecation warnings"; removes the expectation-revealing framing. Partial mitigation for quality-codex.R1-F01.
3. **Q10** — Broadened to include "any requirement to enumerate downstream consumers of contracts being changed". Addresses quality-claude.R1-F05 (G18 coverage).
4. **Q15** — Reframed from "Pipeline Mode Selection ... compare to check_codex_available()" to a general environment-detection helper inventory. Addresses quality-codex.R1-F01 (G27 leak via specific-line citation).
5. **Q16** — Removed the cite-check-specific final sentence; reframed as "what conditions each rubric tier inspects." Addresses quality-claude.R1-F01 (G19 leak).
6. **Q18** — Removed "contradiction-refusal" specific phrasing; broadened to general agent-SDK / tool-use documentation. Addresses quality-claude.R1-F02 (G10 leak).
7. **Q19 (new)** — `[codebase]` cumulative-diff anchor inventory. Addresses quality-claude.R1-F03 + quality-codex.R1-F02 (G4 coverage).
8. **Q20 (new)** — `[codebase]` post-approval plan-split idempotency in `skills/plan/SKILL.md`. Addresses quality-claude.R1-F03 + quality-codex.R1-F02 (G5 coverage).
9. **Q21 (new)** — `[codebase]` `change_type` enum enforcement via threshold lookup. Addresses quality-claude.R1-F04 + quality-codex.R1-F02 (G13 coverage).
10. **Q22 (new)** — `[codebase]` task-tool model-substitution observability. Addresses quality-codex.R1-F02 (G20 coverage).
11. **Q23 (new)** — `[codebase]` code-simplifier pipeline as-built artifact shape. Addresses quality-codex.R1-F02 (G24 coverage).

Final question count: **23** (up from 18). Breakdown: 21 codebase + 2 web.

## Next step

Dispatch R2 to verify no new leakage was introduced by the 6 rewrites and 5 new questions, and that scope coverage is now comprehensive across all 27 goals.
