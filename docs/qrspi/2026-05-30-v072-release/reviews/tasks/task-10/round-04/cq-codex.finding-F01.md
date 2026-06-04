---
finding_id: R4-F01
reviewer_tag: cq-codex
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-verified-file-shape.bats:144
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1957
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2097
---

# cq-codex R4 F01: ID-hygiene violation — QRSPI tokens in test surfaces

QRSPI-internal run/task tokens (`G28`, `D1`, `R2`, `F02`) embedded in test file comments and strings. Per ID-hygiene rules these tokens are forbidden outside `docs/qrspi/`. Replace with descriptive text that preserves intent without run-specific IDs.

Disposition: ACCEPT-WITH-ISSUES, file backlog PI-V072-T10-009 (orchestrator-correctable; one-time cleanup, no fix-cycle needed).
