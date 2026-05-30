---
finding_id: R7-F01
severity: low
change_type: testability
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 7
reviewer: testcov-codex
---

Task 9 baseline-relative expectations not directly testable from final state

plan.md line 269 Task 9 test expectations contain:
- "preserved with identical line content before and after the frontmatter deletion"
- "per-file diff for each of the 41 modifications shows exactly one deletion (the model: frontmatter line)"

These compare before-vs-after state. A BATS final-state harness cannot verify "identical before/after" or "exactly one deletion" without an explicitly pinned baseline reference (commit ref, snapshot path).

Singleton finding — not raised by testcov-claude across R3-R7 or any other reviewer R3-R7. Task 9 was not in the R7 diff scope.

DISPOSITION: ACCEPT with small surgical fix. Mirror the Task 8 Manual Validation pattern (plan.md line 253). Move baseline-relative expectations to a Manual Validation block. Keep structural-final-state expectations in Test Expectations. Final-state structural lint (test-agent-frontmatter-no-model.bats) already covers the meaningful invariant (no model: key in any frontmatter); the diff-relative expectations are operator-auditable via "git diff HEAD~1 -- 'agents/qrspi-*.md'" and not BATS-testable.
