---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: phasing
round: 4
reviewer: quality-codex
---

## Over-abstraction of acceptance-gate wording reduces checkability

`phasing.md` replaced concrete `change_type` wording with `finding-categorization` in both Slice 1.1 and Phase 1 acceptance gates (`phasing.md:50,54,148,153`). That abstraction makes the gate less checkable because "finding-categorization" is not a concrete field name in the contracted finding schema, while the companion goals artifact still names this surface as "change-type schema enforcement" (`goals.md:9`).

To keep replan/release gates demonstrable and unambiguous, acceptance text should reference the exact schema field (`change_type`) and invalid-value test cases using that literal field name.
