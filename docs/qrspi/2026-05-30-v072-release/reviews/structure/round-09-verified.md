# Structure R9 — Verified findings (post fan-in)

**Round:** 9 (narrow vs R7 commit 6ef4ce6 = HEAD~1 from R8 commit 9096d6c)
**Diff:** 38 lines vs R7 commit (reviews R8's fix delta)
**Scope-hint:** `## File Map`, `## Hook-Point Locations`

## Reviewer fan-in summary

| Reviewer | Result | Notes |
|---|---|---|
| quality-claude | CLEAN | 2 rounds clean now. |
| scope-claude | 1 finding (F01 medium scope) | R8's F03 fix embeds literal anchor phrase → DEFERS violation. |
| quality-codex | NO_FINDINGS | (hand-persisted chat-only) |
| scope-codex | 1 finding (F01 medium scope) | Same finding as scope-claude F01 — independent corroboration. |
| stitching-audit | 3 findings (F01–F03) | |

## Verified findings

| Finding | Severity | Type | Score | Decision | Summary |
|---|---|---|---|---|---|
| scope-claude.F01 + scope-codex.F01 | medium | scope | n/a (auto-KEEP) | KEEP | Literal anchor phrase `"Scope: only \`task_type: code\` tasks."` at L129 violates Structure DEFERS ("test assertion text", "actual SKILL.md content"). Double-corroborated → auto-KEEP per protocol. |
| stitching-audit.F01 | medium | correctness | 80 | KEEP | Mermaid S12 subgraph DM node still reads `scripts/dispatch-agent.sh` while file-map row L37 was switched to OLD name `scripts/run-codex-review.sh` in R8. Internal inconsistency. |
| stitching-audit.F02 | medium | correctness | 28 | **DROP** | Claims Additions A, B, D need anchor-pin test rows like C. Verifier agreed finding over-reaches — A/B are co-located with `!cat` includes (indirectly pinned by existing test); D co-located with `skills:` preload (indirectly pinned); only C is purely standalone, which is why R8 specifically pinned it. Widening would also amplify the scope drift scope-reviewers flagged. |
| stitching-audit.F03 | medium | correctness | 38 | **DROP** | Claims intro should explain why Consumer #9 is excluded from "#4-#8" preload range parallel to the #6 BOTH callout. Verifier noted: #9 has no double-counting issue (only appears once), the table row already says "standalone — no preload", and the suggested fix would pull design rationale ("compromise RED judgment") up into structure intro → altitude overstep. |

## Convergence trend (kept findings)

R7=5 → R8=4 → R9=2. **Significant convergence on the trend line.** Non-stitching-audit reviewers all clean for two consecutive rounds (R8 + R9 quality-claude / quality-codex / scope-claude on its quality-side / scope-codex on its quality-side).

R10 narrow against R9's 2-fix delta is expected to land clean or with 1 minor finding.
