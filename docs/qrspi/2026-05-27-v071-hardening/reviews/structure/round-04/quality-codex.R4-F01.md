---
finding_id: quality-codex-R4-F01
severity: medium
change_type: missing-component
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
artifact: structure
round: 4
reviewer: quality-codex
status: applied
---

Slice 4 omitted a test-file component that design.md G4 test strategy promises ("Parallelize-reviewer agent test pins the Wave sub-section structural rule" + "Existing parallelize unit tests are adapted to the new structure" at design.md:139).

Verified existing parallelize test files in `tests/unit/`:
- `test-no-parallel-group-vocab.bats`
- `test-parallelize-owns-defers.bats`
- `test-parallelize-vocab.bats` (already pins agent body content per `grep -l qrspi-parallelize-reviewer.md tests/`)
- `test-scope-reviewer-parallel-with-claude.bats`

**Resolution:** added Slice 4 row for `tests/unit/test-parallelize-vocab.bats` (Modify): assertion pinning the `### Wave N` sub-section structural rule against `agents/qrspi-parallelize-reviewer.md`, plus adaptation of existing Wave-vocabulary assertions to reference the new sub-section grouping shape.
