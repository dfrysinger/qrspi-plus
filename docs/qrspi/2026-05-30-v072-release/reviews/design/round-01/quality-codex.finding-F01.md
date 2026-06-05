---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L11-L13
  - docs/qrspi/2026-05-30-v072-release/design.md:L652-L656
artifact: design
round: 1
reviewer: quality-codex
---

The design explicitly excludes test strategy from design scope ("test spec belongs to Plan"), which leaves no design-level testing approach that names unit/integration/contract/e2e coverage boundaries. This fails the design-quality requirement that design include an appropriate test strategy at design altitude.
