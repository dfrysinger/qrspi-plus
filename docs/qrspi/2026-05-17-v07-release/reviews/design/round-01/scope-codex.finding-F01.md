---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L620-L620, docs/qrspi/2026-05-17-v07-release/design.md:L829-L833, docs/qrspi/2026-05-17-v07-release/design.md:L872-L872, docs/qrspi/2026-05-17-v07-release/design.md:L927-L931]
artifact: design
round: 1
reviewer: scope-codex
---

The design artifact is authoring implementation sequencing and phase-placement instructions, which Design defers to Phasing. Lines 620, 829-833, 872, and 927-931 tell Phasing which goals should land early, co-ship, or run in a specific implementation order. The design may record dependency rationale and architectural coupling, but it should not prescribe phase boundaries or release sequencing. Fix by rewriting these as dependency constraints and handoff notes for Phasing to consume, leaving actual ordering and phase grouping to the Phasing artifact.
