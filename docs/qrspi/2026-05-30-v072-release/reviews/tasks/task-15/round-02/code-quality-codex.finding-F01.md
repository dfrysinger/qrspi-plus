---
finding_id: R2-F01
reviewer_tag: code-quality-codex
round: 2
severity: medium
change_type: maintainability
referenced_files: [tests/integration/test-reference-gate-pause.bats]
adjudication: dismissed
---
**Claim:** `[G18-consumers]` token in the new bats test name violates ID-hygiene (G-prefixed IDs forbidden outside docs/qrspi/).

**Adjudication: DISMISSED — dismissed-convention pattern (same as T14 [G15-sweep]).** The ID-hygiene rule forbids internal QRSPI IDs in production code identifiers and comments, NOT in bats test-name spec labels. This test file already uses `[G15-sweep]` (22 pins, T14, passed full review) and `[G18-consumers]` (28 pins, T15 R1, passed spec-gate) as bracketed spec-traceability labels — they are the file's established convention for mapping each pin to its goal. Renaming this ONE pin to `[consumers]` would make it inconsistent with its 28 siblings and break the goal-traceability grep convention. The label is a spec identifier in a test name (a documented protocol carve-out), not an evergreen internal-ID leak.
