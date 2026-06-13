---
finding_id: R8-F01
severity: medium
change_type: correctness
referenced_files: ["plan.md:L1064-L1070"]
artifact: plan
round: 8
reviewer: test-coverage-codex
---

T19c parent-mismatch test bullets use inconsistent error-token wording (`stage-commit-parent-mismatch:` with colon in one bullet, without colon in another, "halts naming missing/extra tip" without diagnostic-token assertion in others). Fix: every parent-mismatch bullet asserts the same exact named diagnostic token + payload (wrong first parent SHA / missing tip / extra parent).
