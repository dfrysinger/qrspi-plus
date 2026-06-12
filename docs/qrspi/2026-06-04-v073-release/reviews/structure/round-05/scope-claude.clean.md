---
reviewer: scope-claude
artifact: structure
round: 5
status: clean
---

# Scope review — clean

No scope/boundary findings against `skills/structure/owns-defers.md`.

## Diff under review

Round-05 diff (`reviews/structure/round-05/round-05.diff`) touches only:

1. **G5 file-map table** — adds one row (`tests/lint/test-integrate-test-skill-phase-base-write.bats`, Create) and expands the existing `tests/unit/test-orchestration-boundary-check.bats` row's Responsibility column with additional fixture-coverage prose (per-phase phase-base source, multi-field sidecar tolerance, missing- and malformed-file negative cases).
2. **T1 acceptance-stitching bullet** for G5 — re-enumerates the per-fixture coverage and adds the new T2 lint reference.

## OWNS check — pass

All three edits sit inside Structure's owned territory:

- **File map** (which file holds which component): the new bats row names the test file path + the module-boundary contract it locks (anchor-phrase presence on `skills/integrate/SKILL.md` + `skills/test/SKILL.md`).
- **Test-architecture coverage boundary**: the expanded `test-orchestration-boundary-check.bats` Responsibility column enumerates the scenarios that bound the test file's coverage — the Structure-altitude form ("what the file covers"), not the Plan/Implement-altitude form ("what each test asserts line-by-line").
- **Per-type stitching of per-solution acceptance**: the updated T1 G5 acceptance bullet performs the canonical stitching from per-CD/per-goal Acceptance into the T1 taxonomy, matching the form already used for G1–G8 above and below it.

## DEFERS check — pass

- **Per-task assertions / unit-test code** (the deferral most at risk): the fixture prose stays at coverage-boundary granularity ("multi-field tolerance: sidecar carries both `integration_base_sha=` and `task_tip_shas=` lines; script reads the first, ignores the second"; "missing phase-base file → assert the named diagnostic"). This is the same altitude as the pre-existing G6 row for `tests/unit/test-validate-stage-commit-parents.bats` ("correct task-tip set but wrong first-parent → halt naming the wrong first-parent SHA") and the G7/G8 rows — establishing that this level of fixture enumeration is the existing Structure convention in this artifact, not new drift. Plan's per-task `Test Expectations` blocks and Implement's bats assertion code remain unauthored here.
- **Per-solution choice rationale / alternatives** — none introduced.
- **Per-solution end-to-end flows or sequence diagrams** — none introduced.
- **External-system contracts / vendor research** — none introduced.
- **Detailed solution descriptions** — the rows remain declarative file-map entries, not re-litigations of design.md's G5 solution.

## Lexical drift scan — pass

No implementation code, no per-task `Test Expectations` headers, no phase-assignment imperatives ("the Implementer should…"), no design-altitude rationale prose. The new row's Responsibility column uses the same declarative file-map verb form as its neighbors.

## Coverage-gap check — pass (and improved)

The diff also closes a latent coverage gap: previously the file-map row for `tests/unit/test-orchestration-boundary-check.bats` had been extended with per-phase phase-base coverage but the T1 stitching bullet had not been updated to match. Round-05 brings the T1 bullet into sync, restoring the OWNS-required per-type stitching invariant. The new T2 lint row likewise stitches to the SKILL-prose phase-base write step that G5's `skills/integrate/SKILL.md` and `skills/test/SKILL.md` rows introduced, closing the matching write-side coverage that the read-side fixtures depend on.
