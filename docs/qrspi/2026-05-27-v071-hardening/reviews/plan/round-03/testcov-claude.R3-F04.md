---
finding_id: R3-F04
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-claude
---

Task 8: Path-scope protection downgraded to unverifiable prose

R3 removed "path-scope assertion in the modify-pass" mechanism but the replacement "The Task 8 commit modifies no path under docs/qrspi/2026-04-29-v0.4-bundle/ or docs/superpowers/" states a desired condition without naming any test mechanism.

Fix: restore mechanism (either BATS test grepping the diff list, or explicit "Manual verify: git diff --name-only HEAD~1 lists no path under..." label).
