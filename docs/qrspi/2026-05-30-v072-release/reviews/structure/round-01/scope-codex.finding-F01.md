---
finding_id: R1-F01
severity: medium
change_type: scope
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Structure OWNS "section-list contracts per file" (per v0.7.1 owns-defers.md), but the
artifact currently provides file paths, actions, and responsibilities only and does
not specify required top-level section contracts for the listed SKILL / agent /
protocol files in the File Map. Add explicit per-file section/heading contract
definitions (at least for files whose section structure is load-bearing — e.g.,
`skills/structure/SKILL.md` after G35, `skills/_shared/structure-altitude-boundary.md`,
`skills/_shared/design-altitude-boundary.md`, `agents/qrspi-structure-scope-reviewer.md`)
to satisfy owned scope.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
