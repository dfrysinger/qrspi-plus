---
finding_id: R4-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

"Captured stdout is non-empty" for mocked dispatch is underdetermined

Task 7 mocked dispatch assertions only require non-empty stdout. Satisfied by any accidental print (e.g., a debug echo). Test writer needs an anchor: a content pattern or mock sentinel.

Fix: assert captured stdout matches a known mock sentinel pattern (e.g., the mock's known output marker) or anchor to a content pattern that proves the dispatch actually ran.
