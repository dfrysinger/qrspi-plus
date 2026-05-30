---
finding_id: F02
severity: medium
change_type: plan_update
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: test-coverage-codex
---

## Task 6 unrecognized-host expectation missing

Convergent with security-claude F02, testcov-claude F07. Add test expectation for `check_codex_available()` with unrecognized host argument returning non-zero with diagnostic.
