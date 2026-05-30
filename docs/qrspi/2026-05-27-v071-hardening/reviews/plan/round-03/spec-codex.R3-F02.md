---
finding_id: R3-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: spec-codex
---

Task 8 lacks explicit RED/GREEN dispatch distinction

All other TDD tasks include "Dispatch order: test-writer first, implementer second (RED-verification gate between)." Task 8 omits this. Task 8 is mechanical deletion, but the absence-assertion bullets in test files are net-new and warrant RED-first authoring.

Fix: Add explicit RED-first test-writer + GREEN implementer dispatch-order line to Task 8.
