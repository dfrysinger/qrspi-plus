---
finding_id: F01
reviewer_tag: code-simplifier-claude
round: 4
severity: suggestion
category: dead-code / duplication
files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# Acceptance-test AC1/AC2/AC3 duplicate existing unit-test prose-pin assertions

## What's happening

`test-phase1-acceptance.bats` (lines added in this task) contains three
standalone `@test` blocks — `[AC1]`, `[AC2]`, and `[AC3]` — that do nothing
but grep `agents/qrspi-finding-verifier.md` for static documentation text:

| Acceptance test | What it greps for |
|---|---|
| AC1 | `defect_class:` present; regex `^[a-z0-9][a-z0-9-]*$` present |
| AC2 | `awk` slice between step 5 and step 6; `(≤\|<=) ?30\|30[- ]char` present |
| AC3 | `defect_class: *unspecified` present |

`test-verified-file-shape.bats` (also modified in this task) contains
**exactly the same checks**, already exercised as full unit tests:

| Unit test | What it checks |
|---|---|
| "verifier agent body documents a Defect-class rubric step between Score and Write-sidecar" | same `awk` slice + `defect[- ]class` and `defect_class:` greps |
| "verifier agent body documents defect_class shape: kebab-case, ≤30 chars, regex anchor" | same `(≤\|<=) ?30` and kebab-case greps |
| "verifier agent body documents 'unspecified' fallback for absence-of-signal defect_class" | same `defect_class: *unspecified` grep |

In addition, the unit test's version of the AC2 check is *more precise*: it
greps within the awk slice and also covers the regex anchor and kebab-case
prose in a single test, while the acceptance test only covers the character-cap
phrasing in the slice (the regex check runs file-wide). Neither test adds
anything the other doesn't cover.

## Why this matters

Every time the agent file changes, the same grep must pass in both suites.
Reviewers reading failures have to figure out which suite owns the assertion.
The acceptance file should focus on behavioral ACs (AC4 — fan-in script
integration, AC5 — YAML template parse + field shape), not repeat static-doc
grep work that the unit suite already pins.

## Suggested simplification

Remove `[AC1]`, `[AC2]`, and `[AC3]` from `test-phase1-acceptance.bats` and
replace them with a single cross-reference comment pointing at the unit file:

```bash
# AC1-AC3 (defect_class: shape, ≤30-char cap, unspecified fallback) are
# prose-pin assertions exercised in tests/unit/test-verified-file-shape.bats.
# This suite covers only the behavioral and structural ACs (AC4, AC5).
```

The section comment block (lines 88–106) that lists "Coverage: AC1–AC5" can
be trimmed to "Coverage: AC4–AC5" accordingly.

**No functional test coverage is lost** — the unit tests remain and are already
run by the same CI job. The acceptance suite is simplified to the behavioral
and template-shape assertions it uniquely exercises.
