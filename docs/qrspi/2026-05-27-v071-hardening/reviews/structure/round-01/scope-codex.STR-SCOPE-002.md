---
finding_id: STR-SCOPE-002
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
artifact: structure
round: 1
reviewer: scope-codex
status: applied
---

Structure OWNS "section-list contracts per file," but this artifact does not define top-level section contracts for the listed files (it mostly gives change responsibilities). This leaves an owned structure surface under-specified.

**Resolution:** added `## Section Contracts` section enumerating top-level (`##`/`@test`/heading) contracts for the 2 created `.bats` files and for the 3 modified SKILL.md files whose section boundaries are reshaped by this release.
