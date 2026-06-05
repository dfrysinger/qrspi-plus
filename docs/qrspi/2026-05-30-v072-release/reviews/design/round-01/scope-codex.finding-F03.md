---
finding_id: R1-F03
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L11-L18
  - docs/qrspi/2026-05-30-v072-release/design.md:L207-L213
  - docs/qrspi/2026-05-30-v072-release/design.md:L1271-L1279
artifact: design
round: 1
reviewer: scope-codex
---

Scope compliance gap against Design-OWNS: there is no clear, consolidated design-level test strategy section (test types/layers/framework posture at architecture altitude). Instead, the artifact mostly provides per-goal acceptance/test mechanics at implementation granularity. OWNS requires design-level strategy explicitly, separate from downstream test-spec detail.
