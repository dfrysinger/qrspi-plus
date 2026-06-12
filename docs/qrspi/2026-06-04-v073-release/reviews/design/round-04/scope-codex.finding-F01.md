---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L9-L49, docs/qrspi/2026-06-04-v073-release/design.md:L130-L236]
artifact: design
round: 4
reviewer: scope-codex
---

Boundary drift into **Structure-owned file architecture**: the design prescribes concrete file placement and module ownership (e.g., exact script filenames, exact agent/skill files to edit, and where specific logic must live). Under Design DEFERS, "which file holds which component / directory layout / module boundary lines" is deferred. Keep this artifact at outcome altitude (what behavior/invariant each solution must provide), and move exact file-location prescriptions to structure/plan artifacts.
