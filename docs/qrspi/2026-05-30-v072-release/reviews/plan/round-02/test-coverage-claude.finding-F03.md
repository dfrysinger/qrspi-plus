---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T29
severity: medium
change_type: correctness
---

# F03 — T29 references a lint-test target file that has no creation responsibility, DoD, or test expectations

## What

T29's `**Target files:**` line includes:

> create `tests/lint/test-design-altitude-boundary-include.bats`

But T29's body — Scope-In, Definition of done, and Test expectations sections
— never mentions this file again. There are no DoD bullets describing what the
lint test must assert, and no Test-expectations bullets describing what
acceptance checks to run against it. The same omission appears at T37 (Target
files lists `tests/lint/test-structure-altitude-boundary-include.bats` for
creation but Scope-In / DoD / Test-expectations are silent on it).

Out-of-scope bullet at T29 says:

> Test-code or lint-test additions for the include guard — explicitly out of
> this prompt-prose task.

This directly contradicts the Target-files row that says the lint test file
must be created.

## Why this matters

For T29: the test-writer phase cannot generate acceptance checks for the lint
file because there is no requirement to test. The implementer either:

1. Creates an empty/stub `.bats` file (satisfies Target files; satisfies the
   Out-of-scope "no lint-test additions" by being empty; fails to provide any
   actual lint coverage).
2. Authors a non-trivial lint test (violates the Out-of-scope ban), with no
   acceptance criteria for what assertions it must contain.
3. Does not create the file at all (fails the Target-files requirement).

All three outcomes are defensible against this plan, and none are testable.

For T37: same shape. The `tests/lint/test-structure-altitude-boundary-include.bats`
file is in Target files with no DoD or test-expectation coverage.

## Recommended fix

Pick one resolution per task:

- **If lint coverage is required**: remove the contradictory Out-of-scope ban
  in T29; add DoD bullets describing what the lint must assert (e.g., "lint
  fails when either consumer file lacks the literal `!cat
  skills/_shared/design-altitude-boundary.md` directive"); add matching
  test expectations.
- **If lint coverage is out of scope for v0.7.2**: remove the lint file from
  Target files in T29 and T37; let a future task own it.

The Target-files row, Out-of-scope ban, and silence in DoD/Test expectations
cannot coexist; one of them is wrong.
