---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L895-L899, docs/qrspi/2026-05-17-v07-release/design.md:L1050-L1054, docs/qrspi/2026-05-17-v07-release/design.md:L1112-L1115]
artifact: design
round: 2
reviewer: quality-codex
---

The G7 test surface is internally inconsistent. Decision 4 and the cross-cutting test strategy both state that G7 has no CI BATS backstop and is enforced through implementer self-check plus reviewer visibility, while G18 has the BATS backstop. The per-goal summary then lists G7's primary test surface as `Implementer self-check + BATS backstop`, which reverses that decision and would send Plan toward authoring a test the design explicitly rejected. Fix the summary row for G7 to match the earlier contract, for example `Implementer self-check + reviewer visibility`.
