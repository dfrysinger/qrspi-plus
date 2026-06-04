---
finding_id: F03
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 1
task: 35
severity: low
change_type: completeness
file: tests/acceptance/test-review-pause.bats
lines: "251-260"
status: open
---

# F03 — Fabricated-citation test only asserts negative routing

Test 10 asserts (1) chat does NOT route to operator-intervention and (2) fabricated string not verbatim in SKILL.md. Routing to normal-review-round is exactly what an uncited clean reply does — no positive signal that fabrication was detected/rejected.

**Recommendation:** Add comment noting negative-routing is necessary-but-not-sufficient; orchestrator-side fabrication detector is the load-bearing surface.
