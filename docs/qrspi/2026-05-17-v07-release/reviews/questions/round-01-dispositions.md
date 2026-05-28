---
round: 01
artifact: questions
status: applied
---

# Round 01 dispositions

## Findings inventory

- quality-claude: 3 (1 high/correctness, 1 medium/correctness, 1 medium/scope)
- quality-codex: 1 (high/correctness — duplicate of quality-claude R1-F01)

## Per-finding dispositions

| Finding | Disposition | Action / Rationale |
|---|---|---|
| quality-claude R1-F01 (high/correctness) | Applied | Pervasive goal leakage across Q4, Q5, Q8, Q12, Q13, Q14, Q17, Q22, Q23, Q24. Each listed question rewritten to drop goal-derived vocabulary, candidate-fix shape, exemplar model names, citation specifics, and token-form enumerations. Q16 separately rewritten under R1-F02 since the leak there had a distinct path-citation dimension. |
| quality-claude R1-F02 (medium/correctness) | Applied | Q16 rewritten to drop the unreachable `~/.claude/projects/.../reference_keeplii_vfr_agent.md` memory-path citation and G11's "spec deltas vs. source-fidelity" / "drop this from source" vocabulary. Now asks about the in-repo agent file (if present) and how task-spec templates surface intentional deviations from a referenced source. |
| quality-claude R1-F03 (medium/scope) | Applied | Added Q26 ([codebase] dispatcher inventory and work shape — names no specific tolerance candidates) and Q27 ([web] A/B replay methodology prior art for LLM coding agents). These cover the two G5 research surfaces the original 25 questions did not surface. |
| quality-codex R1-F01 (high/correctness) | Resolved-by-other | Same defect class as quality-claude R1-F01 (pervasive goal leakage). The R1-F01 rewrites already cover the specific surfaces quality-codex named (policy, DeepSeek/Kimi, Medium article, Plan post-approval split, context-summary shims, test-writer split, Parallelize vocabulary, reference-gate, CI, evergreen-prose). |

## Notes

Both reviewers agreed decisively on the leakage diagnosis. Rewrites preserve every research surface the original set covered — no question was deleted; the change is purely tone (drop goal-derived tokens). Two new questions added to close the G5 gap.
