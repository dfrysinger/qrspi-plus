---
task_id: fix-int-w23-r01-t01
task_type: lightweight
status: approved
source_finding: integration-codex.F01 (severity: high, change_type: correctness, score 82)
parent_round: integration-wave-23/round-01
---

# fix-int-w23-r01-t01: Align implement/SKILL.md wave-dispatch text with T4 parallelize reshape

## Context

T4 (Wave 3) reshaped `skills/parallelize/SKILL.md` so that wave ordering is read from `### Wave N` sub-section headings under Branch Map, and removed the standalone `## Execution Order` section. This was pinned by `tests/unit/test-parallelize-vocab.bats:288-293` (no `## Execution Order` H2 anywhere in parallelize/SKILL.md).

The consumer side — `skills/implement/SKILL.md` — was not updated to match. Two stale references remain:

- **Line 361** (read-inputs step) lists "Execution Order narrative" as a required section of `parallelization.md`.
- **Line 371** (wave dispatch loop) iterates "for each wave in the Execution Order, in order".

A correctly-produced post-T4 `parallelization.md` will contain neither an "Execution Order narrative" section nor any other field named "Execution Order." This is a producer/consumer contract mismatch: the producer's spec forbids the section, the consumer's spec requires it.

## Scope (target files)

- `skills/implement/SKILL.md` (text edits at L361 and L371)
- `tests/unit/test-implement-skill-vocab.bats` (NEW — pinning test, see Test Expectations)

## Out of scope

- Any other change to `skills/implement/SKILL.md` content semantics.
- Any change to `skills/parallelize/SKILL.md` (already correctly updated by T4).
- Any change to `agents/qrspi-parallelize-reviewer.md` (already correctly updated by T4).
- Touching `skills/implement/SKILL.md:488` ("Execution order: spec-reviewer first ...") — this is a different domain (reviewer ordering within a per-task fan-out), not parallelization wave ordering. Leave it alone.

## Implementation

### Edit 1: `skills/implement/SKILL.md:361`

Find:
```
1. **Read inputs.** Full pipeline: read `parallelization.md` (Branch Map + Stage Commits + Execution Order narrative; if a `## Runtime Adjustments` section exists from a prior session, load its overrides into the in-memory base-resolution table).
```

Replace with:
```
1. **Read inputs.** Full pipeline: read `parallelization.md` (Branch Map organized into `### Wave N` sub-sections + Stage Commits; if a `## Runtime Adjustments` section exists from a prior session, load its overrides into the in-memory base-resolution table).
```

### Edit 2: `skills/implement/SKILL.md:371`

Find:
```
    - **Full pipeline — for each wave** in the Execution Order, in order:
```

Replace with:
```
    - **Full pipeline — for each `### Wave N` sub-section under Branch Map**, in ascending N order:
```

### Edit 3: New unit test `tests/unit/test-implement-skill-vocab.bats`

Create a new bats file that pins both of the above invariants against future regression. Two tests:

1. `[fix-int-w23-r01-t01] implement/SKILL.md does not reference a standalone parallelization-level "Execution Order" section or narrative` — assertion: `grep -nE 'Execution Order narrative|in the Execution Order' skills/implement/SKILL.md` returns no matches. Rationale: the phrase "Execution Order" remains acceptable in other domains (e.g., reviewer fan-out ordering at L488: "Execution order: spec-reviewer first ..."); the test pins only the two specific phrases that referred to the parallelization-level section T4 removed.
2. `[fix-int-w23-r01-t01] implement/SKILL.md reads wave ordering from Branch Map ### Wave N sub-sections` — assertion: `grep -nE '### Wave N\` sub-section' skills/implement/SKILL.md` returns at least one match. Anchors the new contract so a future re-edit that drops the new vocabulary fails loudly.

Use the existing test-helpers loader pattern from neighboring bats files (e.g., `tests/unit/test-parallelize-vocab.bats`). The new file lives at `tests/unit/test-implement-skill-vocab.bats`. No test-helpers changes required.

## Test Expectations

**Pre-edit state (RED):**

- `bats tests/unit/test-implement-skill-vocab.bats` — FAILS (file does not exist yet → bats exits non-zero with "file not found")
- After creating the bats file but BEFORE the two SKILL.md edits:
  - Test 1 FAILS — the regex `Execution Order narrative|in the Execution Order` matches at L361 and L371.
  - Test 2 FAILS — the new "`### Wave N` sub-section" anchor language is not present.

**Post-edit state (GREEN):**

- `bats tests/unit/test-implement-skill-vocab.bats` — PASSES (both tests).
- `bats tests/unit/` (full unit suite) — 1313 → 1315 ok (added 2 tests; no existing tests touched). All existing tests still PASS — verify by running the full unit suite.
- `bats tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — UNCHANGED pass count (this fix does not touch acceptance behavior).

**Regression check** (no test added; manual grep):
- `grep -n 'Execution order' skills/implement/SKILL.md` — must still match at L488 (reviewer fan-out ordering). The fix preserves this unrelated phrase.

## Rationale

This is a documentation-correctness fix for a cross-skill contract mismatch. The implementation is two text-substitution edits in a SKILL.md plus a small unit test that pins the new vocabulary. Lightweight task type (no production-code logic change; doc + small test only). Per qrspi-plus convention, lightweight tasks dispatch via `qrspi-implementer-lightweight` and do not require test-writer / spec-reviewer fan-out — single-pass implement + per-task quality review.
