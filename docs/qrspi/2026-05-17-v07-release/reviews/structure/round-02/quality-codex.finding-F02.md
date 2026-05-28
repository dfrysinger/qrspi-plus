---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L101-L108, docs/qrspi/2026-05-17-v07-release/design.md:L209-L238]
artifact: structure
round: 2
reviewer: quality-codex
---

Slice 7 maps G4 almost entirely to the cache probe plus a `skills/structure/SKILL.md` placeholder, but the approved design accepts two complementary mechanisms: prompt caching and narrow Reads via a section-anchor index. Design says Structure and Plan must decide index refresh details and test that indexed Reads fetch byte-identical source slices. The current structure only reserves a placeholder and a no-summary-shim test, so downstream Plan has no concrete file/module/test surface for the section-anchor index or narrow-Read consumers.

Fix: add concrete structure entries for the section-anchor index mechanism, including where index metadata lives, which skill or script refreshes it, which dispatch sites consume it, and a test that verifies indexed line-range Reads match the source slice byte-for-byte.
