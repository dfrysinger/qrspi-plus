---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T27
severity: high
change_type: correctness
---

# F01 — T27 reviewer-protocol antagonist-pattern enforcement clause: test expectations cannot be deterministically verified

## What

T27's round-01 extension added two new Scope-In and DoD requirements covering
`skills/reviewer-protocol/SKILL.md`:

1. The reviewer-protocol clause "requires reviewer subagents to surface a
   finding when an artifact carries any CD-2 named antagonist pattern."
2. "The clause is inserted alongside (NOT replacing) existing
   finding-schema/`change_type` requirements and uses the canonical
   `change_type: style` or `change_type: clarity` enum value per the locked
   snippet's filter taxonomy."

The matching test expectation reads:

> Grep audit of `skills/reviewer-protocol/SKILL.md` confirms the antagonist-
> pattern enforcement clause is present and references the CD-2 named patterns
> vocabulary from the locked `skills/_shared/evergreen-output-rule.md` snippet
> (no duplicated antagonist-pattern list — the reviewer clause cites the
> snippet rather than copying it).

This is unverifiable as written:

- **"Clause is present"** — no literal anchor phrase, heading, or sentence the
  grep must find. Test cannot fail deterministically.
- **"References the CD-2 named patterns vocabulary"** — the locked CD-2
  snippet body is not yet authored at plan-write time, so the test author has
  no concrete anchor strings to assert on. What greppable token proves
  "references"? A path string? A specific antagonist-pattern name?
- **"No duplicated antagonist-pattern list"** — no rule for what counts as
  duplication. If the clause names 2 of the 6 antagonist patterns by name,
  does it duplicate? What is the threshold?
- **`change_type: style` / `change_type: clarity` requirement is in DoD/Scope
  but completely absent from test expectations.** A correct implementation
  that uses `change_type: correctness` (wrong taxonomy) would pass the tests.
- **"Alongside (NOT replacing) existing finding-schema/`change_type`
  requirements"** is in DoD but no test expectation verifies the pre-existing
  finding-schema sections remain present after the edit. A regression that
  deletes the original requirements while adding the new clause would pass.

## Why this matters

The test author for T27 cannot generate a deterministic acceptance check from
these expectations. The most likely outcome is one of:

1. The test author invents anchor strings, which then don't match the actual
   implementer-written prose, producing brittle pass/fail noise.
2. The test author writes a vacuous existence assertion that any non-empty
   edit to `reviewer-protocol/SKILL.md` would satisfy.
3. The implementer ships a clause that violates the `change_type` taxonomy
   constraint or quietly deletes existing finding-schema text, and tests
   accept it.

## Recommended fix

Add concrete, greppable anchors to the test expectations:

- Name a literal heading or anchor phrase the reviewer-protocol clause must
  introduce (e.g., `### Evergreen-Output Rule Enforcement` or a specific
  sentence like "surface a finding for any CD-2 named antagonist pattern").
- Add a test expectation that asserts the clause text contains `change_type:
  style` or `change_type: clarity` (and contains neither `change_type:
  correctness` nor `change_type: scope` in that paragraph).
- Add a "no removal" assertion: name the literal heading(s) of the existing
  finding-schema / `change_type` sections that must still be present after
  the edit (regression guard for the "alongside (NOT replacing)" DoD bullet).
- Specify how "references the snippet" is greppable — e.g., the clause must
  contain the literal path string `skills/_shared/evergreen-output-rule.md`
  exactly once.
- Specify the "no duplicated antagonist-pattern list" check by literal
  pattern: e.g., the clause body MUST NOT contain more than N of the
  antagonist-pattern category names (`session/drafting notes`,
  `version-history narration`, `inside baseball`, etc.) that appear in the
  locked snippet.
