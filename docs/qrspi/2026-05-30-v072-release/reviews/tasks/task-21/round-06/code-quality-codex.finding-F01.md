---
finding_id: F01
reviewer: code-quality-codex
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-dispatch-agent.bats:1836, tests/unit/test-dispatch-agent.bats:1841]
---
**ID hygiene violation in test comments.** New companion-hardening section uses `F01`/`F02` finding-tracker tokens in `Fix 1 (F01):` and `Fix 2 (F02):` comment blocks. Replace with descriptive text.
