---
finding_id: R1-F01
severity: high
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` is missing `skills/_shared/verifier-dispatch-prose.md` from the file
map, even though CD-4/G12 in `design.md` explicitly locks this file and requires it
to be included by both `using-qrspi/SKILL.md` and `implement/SKILL.md`. This leaves
a design-locked shared snippet absent from the file map, breaking the structure
matches design quality check.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
