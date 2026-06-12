---
finding_id: R7-F01
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/design.md:L13-L55
  - docs/qrspi/2026-06-04-v073-release/design.md:L505-L563
artifact: design
round: 7
reviewer: scope-codex
---

Boundary drift: design prescribes concrete file architecture and implementation placement (exact script/file paths, where shared content must live, directory-level layout decisions). Keep design at outcome/component-contract altitude; move file-location commitments to structure.md.
