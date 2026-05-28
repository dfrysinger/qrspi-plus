---
round: 02
artifact: questions
status: applied
---

# Round 02 dispositions

## Findings inventory

- quality-claude: 9 (4 high/correctness, 5 medium/correctness)
- quality-codex: 1 (high/correctness — systemic restatement of the leakage class)

## Per-finding dispositions

| Finding | Disposition | Action / Rationale |
|---|---|---|
| quality-claude R2-F01 (medium/correctness) | Applied | Q2 — dropped `(per-role defaults, per-task overrides, layered precedence)` parenthetical that named G1's candidate schema shapes verbatim. |
| quality-claude R2-F02 (medium/correctness) | Applied | Q5 — rewrote to drop the "shell-side" foreclosure of the in-process alternative and the session-state/API-key/error-fallback enumeration lifted from G2. Now asks neutrally about invoking third-party LLM endpoints from CLI-driven or agent harnesses. |
| quality-claude R2-F03 (high/correctness) | Applied | Q9 — rewrote to drop both verbatim G4 candidate names (summary shim, file index with section anchors) and the source-of-truth/drift framing. Generalized to "mechanisms agent frameworks use to reduce repeated context input." The freshness/accuracy half split off as new Q28. |
| quality-claude R2-F04 (medium/correctness) | Applied | Q11 — dropped `(shared context loss vs. separation of concerns)` parenthetical that lifted G6's "Why we care" dichotomy. |
| quality-claude R2-F05 (high/correctness) | Applied | Q12 — trimmed to current-state only; second clause (restricts identifiers from edited files) split off as new Q29 with neutral wording. |
| quality-claude R2-F06 (high/correctness) | Applied | Q14 — replaced "define or contradict" with "defined or assumed" so the cross-check is not pre-asserted as a known contradiction. |
| quality-claude R2-F07 (high/correctness) | Applied | Q15 — trimmed to current-state only; second clause (gating before downstream consumers fire) split off as new Q30 with neutral "validate or version reference artifacts" wording. |
| quality-claude R2-F08 (medium/correctness) | Applied | Q18 — dropped "in a worktree-safe way" qualifier that pre-asserted G13's known worktree-path collision. |
| quality-claude R2-F09 (medium/correctness) | Applied | Q26 — trimmed "which subset has bounded prompts that lend themselves to mechanical replay" clause that named the G5/G6 A/B-replay validation methodology. |
| quality-codex R2-F01 (high/correctness) | Resolved-by-other | Same leakage diagnosis as the Claude findings; the per-question rewrites address each surface Codex named (cost-opt routing, plan splitting, context shim/index, test-writer split, parallelize reviewer fixes, CI, evergreen-prose linting). |

## Notes

Round 2 surfaced subtler leakage that round 1 missed — parenthetical enumerations and second-clause hypothesis pre-assertions rather than the obvious verbatim citations. Three split-into-two rewrites added Q28/Q29/Q30. Question total: 30. No questions deleted.
