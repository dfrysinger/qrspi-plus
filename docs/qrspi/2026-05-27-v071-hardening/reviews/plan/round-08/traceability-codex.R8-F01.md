---
finding_id: R8-F01
severity: medium
change_type: traceability
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 8
reviewer: traceability-codex
---

Task 9 test expectation does not trace to G7b problem framing. G7b is about removing unsupported top-level model: declarations that cause Copilot fallback warnings. Forcing each file to contain all three tokens is an over-constraint unrelated to proving G7b acceptance.

DISPOSITION: ACCEPT. Convergent with quality-codex, testcov-claude, spec-codex. Resolved in R9.
