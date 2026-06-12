---
finding_id: R6-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 6
reviewer: scope-codex
---

The design drifts into **Structure-owned file architecture** by prescribing where components/content must live (e.g., G9's explicit placement matrix: content in `using-qrspi/SKILL.md` vs `skills/_shared/<topic>.md` vs `skills/<name>/references/<topic>.md`, plus named snippet file inventory). Under the Design OWNS/DEFERS contract, Design may define outcomes/solutions and acceptance at outcome altitude, but should defer concrete file-location architecture to Structure. Tighten this artifact to design-altitude intent (what must be separated and why), and move mandatory file-placement topology into structure.md.
