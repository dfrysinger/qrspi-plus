---
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/design.md
artifact: design
round: 5
reviewer: quality-codex
---

The test strategy is detailed as acceptance checks per goal, but it does not define design-level test types by level (unit, integration, contract, e2e) and what each level validates. Add an explicit test-strategy section that names each level and maps it to the architecture surfaces/components it verifies.
