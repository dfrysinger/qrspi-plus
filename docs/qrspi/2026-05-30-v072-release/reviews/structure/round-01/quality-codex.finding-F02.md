---
finding_id: R1-F02
severity: medium
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` omits `tests/lint/test-design-altitude-boundary-include.bats`, which
is a required G34 regression guard in `design.md` (D5 + acceptance criteria). The
existing file map includes the G35 counterpart (`test-structure-altitude-boundary-include.bats`)
but not the G34 sibling. This leaves the Design boundary include-drift protection
incomplete in the structure map.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
