---
finding_id: R4-F02
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

Mismatch-warning exit-code phrased relatively ("does not change") instead of absolute (0)

Task 6: "The mismatch diagnostic does not change exit code." Test writer needs the absolute expected value, not a relative-to-what-it-was-before claim. Different writers will resolve differently (some assert ==0, others skip).

Fix: state absolute expected exit code (0 / success exit code of the underlying dispatch).
