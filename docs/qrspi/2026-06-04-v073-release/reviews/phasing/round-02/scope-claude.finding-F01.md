---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/phasing.md:L22]
artifact: phasing
round: 2
reviewer: scope-claude
---

The new Phase 1 "Intra-slice sequencing constraints" bullet crosses Phasing DEFERS into Parallelize (Wave decisions, dependency graph) and Plan (ordered task lists) territory. The bullet self-flags drift ("Wave ordering for these constraints is owned by Plan") and confuses ownership (Wave is Parallelize-owned, not Plan-owned). Constraints already live in `goals.md § Cross-Cutting Notes`; downstream skills read goals.md per their input contracts, so re-stating creates a second source that can drift.

Suggested resolution: delete the bullet, or reduce to a pointer like "Intra-slice sequencing constraints exist for this slice; see `goals.md § Cross-Cutting Notes` (consumed by Parallelize for Wave decisions and by Plan for task ordering)."
