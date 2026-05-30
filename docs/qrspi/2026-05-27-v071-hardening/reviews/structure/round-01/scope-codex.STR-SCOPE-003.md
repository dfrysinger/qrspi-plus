---
finding_id: STR-SCOPE-003
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
artifact: structure
round: 1
reviewer: scope-codex
status: applied
---

The `## CI Pipeline` section includes phasing/replan-gate content ("Phase 1" gate criteria, `phasing.md` reference). Phasing policy is DEFERS territory, so this is boundary drift outside Structure scope.

**Resolution:** stripped the phasing/replan-gate sentence from `## CI Pipeline`. Section now states only the unchanged-workflow facts that Structure owns. Convergent with R1-F03 from scope-claude.
