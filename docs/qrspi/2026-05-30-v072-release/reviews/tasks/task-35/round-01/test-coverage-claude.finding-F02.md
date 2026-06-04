---
finding_id: F02
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 1
task: 35
severity: low
change_type: clarity
file: tests/acceptance/test-review-pause.bats
lines: "121-133, 227-238"
status: open
---

# F02 — `review_round_side_effects` is hardcoded lookup, not behavioral

Helper returns fixed string `"findings_parsed=0 ... round_advance=0"` for input `operator-intervention`. Test 8 asserts that exact string. Tautological w.r.t. helper. Acknowledged by header comment but no inline note explains the tautology.

**Recommendation:** Add comment making tautology explicit OR have helper read expected effects from co-located fixture.
