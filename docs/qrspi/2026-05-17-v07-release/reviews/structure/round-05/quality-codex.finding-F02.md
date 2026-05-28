---
finding_id: R5-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L101-L108, docs/qrspi/2026-05-17-v07-release/design.md:L209-L237]
artifact: structure
round: 5
reviewer: quality-codex
---

The Structure file map reduces G4's section-anchor index mechanism to a placeholder in `skills/structure/SKILL.md`, but the approved design says the release uses two complementary mechanisms and explicitly defines Mechanism B as a JSON-shaped section-anchor index per stable artifact, refreshed when the artifact changes, with tests proving agents read only expected line ranges and the assembled slice is byte-identical. A placeholder does not identify the index file(s), refresh mechanism, consumer changes, or byte-identical slice tests needed to implement that design.

Fix: add concrete G4 structure entries for the section-anchor index artifact(s), refresh/generation mechanism, at least one consumer surface that uses the index for narrow Reads, and tests for expected line ranges plus byte-identical source slices.
