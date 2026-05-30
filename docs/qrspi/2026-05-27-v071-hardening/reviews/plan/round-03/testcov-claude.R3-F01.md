---
finding_id: R3-F01
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-claude
---

Task 6: COPILOT_CLI="" mis-categorized as a "non-empty value"

Current expectation reads `non-empty value other than 1 (including COPILOT_CLI="")` which is internally contradictory. Empty-string and unset are distinct shell states.

Fix: split into 4 expectations: (1) =1 → copilot-cli, (2) unset → claude-code, (3) empty string → claude-code, (4) non-empty non-1 (=0, =true) → claude-code.
