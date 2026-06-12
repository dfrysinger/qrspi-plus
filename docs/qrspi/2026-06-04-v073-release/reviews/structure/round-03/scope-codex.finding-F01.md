---
finding_id: R3-F01
artifact: structure
round: 3
reviewer: scope-codex
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/structure.md:L88
  - docs/qrspi/2026-06-04-v073-release/structure.md:L326-L338
---
Structure defers a Structure-owned module-boundary/file-map contract to Plan. The updated G5 contract says integration/test phase-base anchors have their concrete read paths and capture sites "resolved by Plan" / "Plan's task-carving call," but Structure OWNS the file map and module-boundary contracts that Plan consumes. Without Structure naming the concrete anchor artifacts and writer/reader responsibilities for `--phase integration` and `--phase test`, downstream tasks can invent incompatible locations. Fix by specifying the Structure-level anchor paths/contracts for each phase here, while still leaving implementation internals to Plan/Implement.
