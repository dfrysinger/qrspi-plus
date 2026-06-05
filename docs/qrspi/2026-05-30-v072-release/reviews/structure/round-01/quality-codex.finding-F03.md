---
finding_id: R1-F03
severity: medium
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` does not represent CD-4's locked interaction-mode component surfaces
(`scripts/detect-interaction-mode.sh` and round audit output `.interaction-mode-audit.json`)
that are specified with contract and acceptance criteria in `design.md`. This is a
missing-component gap between design and structure — a file/contract locked by
design.md has no corresponding entry in the file map or interfaces sections.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
