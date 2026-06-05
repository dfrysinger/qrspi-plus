---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L2581-L2597
  - docs/qrspi/2026-05-30-v072-release/design.md:L2024-L2039
  - docs/qrspi/2026-05-30-v072-release/design.md:L2782-L2786
artifact: design
round: 1
reviewer: scope-codex
---

The document includes repeated release/phase assignment decisions (what co-ships in v0.7.2, what moves to v0.7.3+, explicit scope deferrals by release). Those are phasing/roadmap boundary decisions, which OWNS/DEFERS assigns to `qrspi:phasing` rather than design.
