---
finding_id: R6-F01
severity: medium
change_type: modify
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 6
reviewer: testcov-codex
---

Task 7 test expectation is no longer deterministic for transport-invocation proof

"provides evidence" doesn't define exact observable output. Test writer cannot derive deterministic pass/fail.

Fix: Specify exact required observable (fixed mock sentinel string/pattern per transport).

DISPOSITION: Same finding as testcov-claude R6-F01. Apply middle-ground wording that names the behavior (stdout contains a distinguishable marker emitted by the mock) without specifying assertion mechanism or exact string value.
