---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L972-L1014
  - docs/qrspi/2026-05-30-v072-release/design.md:L1659-L1693
  - docs/qrspi/2026-05-30-v072-release/design.md:L2728-L2760
artifact: design
round: 1
reviewer: scope-codex
---

The design artifact crosses into Design-DEFERS territory by specifying implementation-level surfaces (full script logic, exact exit-code handling, verbatim command/file contract details, and concrete test fixture mechanics). Per OWNS/DEFERS, this level belongs to Structure/Plan/Implement, while design should stay at architectural decision altitude.
