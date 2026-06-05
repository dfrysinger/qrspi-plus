---
finding_id: F02
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 2
task: 40
severity: low
change_type: completeness
file: tests/unit/test-ci-workflow-shape.bats
lines: "380-395"
status: open
---

# F02 — No positive control proving scan loop actually iterates

If `scripts/` is renamed/removed, test silently degrades to no-op. Suggest asserting producer pipeline is non-empty.
