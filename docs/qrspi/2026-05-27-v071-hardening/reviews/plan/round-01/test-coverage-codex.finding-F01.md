---
finding_id: F01
severity: medium
change_type: plan_update
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: test-coverage-codex
---

## Task 1 empty-header edge case

Convergent with testcov-claude F02. Add empty-string expectation: empty header name and empty header value pass through `_control_char_check` without die-path (no control bytes present); no false positive.
