---
finding_id: R4-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-codex
---

Manual-only expectations block deterministic acceptance-test generation (Tasks 8 + 10)

Task 8: "Manual verify (pre-merge): git diff --name-only HEAD~1 ..."
Task 10: "freshly installed copy emits zero 'model not available' warnings (manual smoke check)"

These are operator/manual checks not specified as automatable. Test skill can't generate deterministic acceptance tests from them.

Fix: (a) convert to scripted automatable checks with explicit expected outputs, OR (b) move out of "Test expectations" into a separate "Manual validation" section so acceptance-test generation isn't blocked.
