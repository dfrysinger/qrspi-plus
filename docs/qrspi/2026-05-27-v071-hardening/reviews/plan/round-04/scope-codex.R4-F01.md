---
finding_id: R4-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: scope-codex
---

Task 3 hard-coded exact stderr strings cross Plan DEFERS

Task 3 now hard-codes exact stderr strings for both failure branches (`extract_section_fence_aware: anchor heading not found: <heading>` etc.) in test expectations. That is assertion-level text crossing Plan DEFERS (full assertion text belongs to Implement-TDD).

Fix: keep at behavior level — "distinct stderr diagnostics for missing-anchor vs empty-extraction cases, distinguishable by message prefix" — and let test authoring choose exact literals.
