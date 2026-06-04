---
finding_id: F01
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 1
task: 35
severity: medium
change_type: completeness
file: tests/acceptance/test-review-pause.bats
lines: "158-170"
status: open
---

# F01 — Lower-boundary heading not asserted by name

Test 1 verifies upper boundary (`### Refusal Procedure` precedes Anti-Fabrication with no intervening heading) but does NOT assert what heading FOLLOWS Anti-Fabrication. DoD line 40 requires "immediately after `### Refusal Procedure` and before `## Per-Finding Disk-Write Contract`."

Discrepancy: SKILL.md contains no `## Per-Finding Disk-Write Contract` section — the heading immediately after is `## Quick-Tier Finding Disposition` (line 275). Either spec/code drift or task spec wording mismatch.

**Recommendation:** Add assertion that next `## ` heading after Anti-Fabrication is the expected one, or reconcile spec wording with actual structure.
