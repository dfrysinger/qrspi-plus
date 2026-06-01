# stitching-audit.finding-F02

**reviewer_tag:** stitching-audit
**round:** 9
**artifact:** structure
**section:** ## File Map (Slice 1.5) + ## Hook-Point Locations (§G31)
**severity:** must-fix
**kind:** asymmetric test coverage + test-file name/scope mismatch

## Finding

The R8 fix extends `tests/unit/test-author-skill-uses-cat.bats` to also pin the
**standalone Addition C** anchor phrase in `agents/qrspi-plan-test-coverage-reviewer.md`.
This creates two related gaps:

### Gap A — Test file name no longer matches its scope

`test-author-skill-uses-cat.bats` now covers:
1. `!cat` include usage for prompt-prose shared snippets (its original scope)
2. `!cat` include usage for design-boundary snippets
3. The **standalone Addition C** anchor phrase — which explicitly has **no** `!cat`
   (the table row notes "standalone — no `!cat`, no wrapper preload")

The filename implies the file tests `!cat` usage only. Responsibility (3) — pinning a
non-`!cat` inline phrase — is semantically out of scope for the name, making it harder
to discover this coverage and increasing the risk that the Addition C pin is orphaned or
removed during future refactors of the `!cat`-focused sections.

### Gap B — Additions A, B, and D have no parallel anchor-phrase pinning

The R8 fix pins the Addition C anchor phrase by name. The Hook-Point table (§G31) lists
four inline-permanent Additions across four consumer files:

| Addition | Consumer | Location | Pinned by a test row? |
|---|---|---|---|
| A | `skills/plan/SKILL.md` §Per-Task Classification (Consumer #1) | inline | **No** |
| B | `skills/plan/SKILL.md` writer-subagent dispatch payloads (Consumer #2) | inline verbatim | **No** |
| C | `agents/qrspi-plan-test-coverage-reviewer.md` TOP (Consumer #9) | standalone inline | **Yes** (R8 fix) |
| D | `agents/qrspi-design-reviewer.md` review-procedure body (Consumer #6) | inline refinement | **No** |

Silent drift or misplacement of Addition A, B, or D would not be caught by any test row
currently in the file map. The rationale for pinning C ("so silent drift or misplacement
of the scope guard is caught") applies equally to A, B, and D.

## Required fix

**For Gap A:** Either rename the test file to reflect its broader scope (e.g.,
`test-author-skill-prompt-prose-anchors.bats` covering both `!cat` includes and inline
anchors), or move the Addition C anchor assertion to a separate test row (e.g., a new
`tests/unit/test-plan-test-coverage-reviewer-scope-guard.bats`).

**For Gap B:** Add test-row responsibility descriptions to the appropriate file-map rows
for `skills/plan/SKILL.md` (Slice 1.5) and `agents/qrspi-design-reviewer.md` (Slice 1.5)
— or extend a test row — to pin the anchor phrases of Additions A, B, and D so all four
inline-permanent additions are caught by tests.
