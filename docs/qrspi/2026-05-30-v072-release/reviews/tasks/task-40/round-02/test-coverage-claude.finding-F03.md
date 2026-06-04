---
finding_id: F03
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 2
task: 40
severity: low
change_type: completeness
file: tests/unit/test-ci-workflow-shape.bats
lines: "390"
status: open
---

# F03 — Content regex may miss alt spellings

`body-guard|bats-body-assertion` doesn't catch `body_guard`, `body assertion guard`, or hooks that simply invoke `bats tests/lint/`. Known limit of content-match enforcement.
