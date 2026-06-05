# Structure R8 — Verified findings (post fan-in)

**Round:** 8 (narrow vs R6 commit 2559a45 = HEAD~1 from R7 commit 6ef4ce6)
**Diff:** 73 lines vs R6 commit (reviews R7's fix delta)
**Scope-hint:** `## File Map`, `## Hook-Point Locations`

## Reviewer fan-in summary

| Reviewer | Result | Notes |
|---|---|---|
| quality-claude | CLEAN | 4 R7 fix-delta items validated against design.md G31 Distribution Table; all 9 consumers accounted for. |
| scope-claude | CLEAN | 3-check scope procedure clean on R7 fix delta. |
| quality-codex | NO_FINDINGS | gpt-5.3-codex (chat-only — no findings emitted). |
| scope-codex | NO_FINDINGS | gpt-5.3-codex (chat-only — no findings emitted). |
| stitching-audit | 4 findings | All R7-fix-introduced regressions; not new design.md issues. |

## Verified findings (all KEEP — above correctness floor 70)

| Finding | Severity | Type | Score | Decision | Summary |
|---|---|---|---|---|---|
| stitching-audit.F01 | medium | correctness/clarity | 78 | KEEP | L772 intro omits Addition B from "inline-permanent" list — should be A, B, C, D. |
| stitching-audit.F02 | high | correctness | 72 | KEEP | L774 parenthetical "(Consumers #4-#8)" contradicts L784 row showing Consumer #6 in Hook-Point table (it carries Addition D inline AND uses skills preload). |
| stitching-audit.F03 | medium | correctness | 80 | KEEP | No test pins Addition C's anchor phrase ("Scope: only `task_type: code` tasks.") — `test-author-skill-uses-cat.bats` covers `!cat` sites but not standalone inline blocks. |
| stitching-audit.F04 | medium | correctness | 72 | KEEP | Slice 1.2 L37 Modify references NEW name `scripts/dispatch-agent.sh` but Slice 1.4 L60 owns the rename from `scripts/run-codex-review.sh` — file does not yet exist under the NEW path when Slice 1.2 work begins. R7's OLD-keyed rename convention exposed this previously hidden ordering dependency.

## Convergence note

Non-stitching-audit reviewers all clean — substantive convergence on the bulk of the artifact. Only stitching-audit surfaced issues, and all 4 are R7-fix-introduced regressions (not new gaps in upstream design.md). This is the loop catching its own work. Post-fix R9 should narrow to ≤1 finding or clean.

If R9 surfaces more stitching gaps, escalate to user: the structure surface may have unstable equilibrium and may need a stitching-pre-pass before scope-narrowing rounds (plugin issue `g31-incomplete-survey-r6-r7` logged).
