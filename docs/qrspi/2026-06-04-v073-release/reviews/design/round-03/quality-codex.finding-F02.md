---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-codex
---

The design lacks an explicit design-level test strategy that names test layers (unit, integration, contract, e2e) and explains what each layer validates. The document has many acceptance checks, but they are scattered per-goal and do not provide a coherent test strategy structure.  
Fix: add a dedicated “Test Strategy” section that explicitly maps unit/integration/contract/e2e coverage to the proposed architecture and key risk areas.

