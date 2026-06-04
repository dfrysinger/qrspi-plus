---
finding_id: R4-F04
reviewer_tag: tc-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:50
  - tests/unit/test-verified-file-shape.bats:168
---

# tc-codex R4 F04: "Examples present" requirement not covered

Spec L50 requires asserting documented examples are present. Current tests check shape/cap/charset/fallback but no test asserts example token values are documented (e.g., `defect_class: real-defect`, `defect_class: unspecified`). A regression removing examples would not fail tests.

CONVERGENT with gt-codex R4 F02 (same observation from traceability angle).

Disposition: ACCEPT-WITH-ISSUES, file backlog PI-V072-T10-013 (1-line grep test). Closely related to PI-V072-T10-007 (fixture-backed coverage) — fold both into one v0.7.2.x test-coverage patch.
