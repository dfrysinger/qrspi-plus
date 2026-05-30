---
finding_id: R3-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-codex
---

Task 6 detect_host state-matrix expectation not fully crisp

Matrix does not explicitly assert exit code for the two primary states (COPILOT_CLI=1, unset); line 187 is internally inconsistent ("non-empty ... including COPILOT_CLI=\"\"").

Needed: explicit row-by-row matrix with both stdout token AND exit code for: unset, =1, empty string, and representative non-1 values (=0, =true).
