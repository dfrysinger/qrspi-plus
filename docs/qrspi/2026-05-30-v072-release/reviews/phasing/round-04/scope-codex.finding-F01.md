---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L50-L55
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L147-L154
artifact: phasing
round: 4
reviewer: scope-codex
---

## Residual boundary drift in Slice/Phase wording

The R4 wording swap landed (`change_type`/`model_routing` renamed), but the edited Slice 1.1 and Phase 1 gate text still names mechanism-level implementation details (specific config/enum internals) rather than phasing-level outcome boundaries. Under **Phasing DEFERS**, that detail belongs downstream (Structure/Plan/Implement). Keep phasing language at slice/phase deliverable outcomes and move mechanism specifics out of `phasing.md`.
