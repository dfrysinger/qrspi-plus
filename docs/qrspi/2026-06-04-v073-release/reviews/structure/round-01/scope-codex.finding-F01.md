---
finding_id: R1-F01
artifact: structure
round: 1
reviewer: scope-codex
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/structure.md:L88
  - docs/qrspi/2026-06-04-v073-release/structure.md:L139
  - docs/qrspi/2026-06-04-v073-release/structure.md:L316-L318
---

Structure is deferring structure-owned contracts to Plan. Lines 88 and 316-318 leave the concrete phase-base SHA read site for `orchestration-boundary-check.sh` to "Plan," and line 139 leaves the per-skill reference-file enumeration to Plan. Structure owns the file map and module-boundary contracts that Plan consumes; it should declare the concrete file/path/interface commitments here rather than assigning those structural choices downstream.
