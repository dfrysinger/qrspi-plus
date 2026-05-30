# Finding F09: Task 8 — "Historical run records unmodified" is not a verifiable automated test expectation

**Artifact:** plan.md
**Task:** Task 8 (G7a — cache mechanism retirement)
**Category:** Test Expectation Quality
**Severity:** advisory

## Problem

The last test expectation is:

> "Historical run records under `docs/qrspi/2026-04-29-v0.4-bundle/` and `docs/superpowers/` are unmodified"

This expectation has no specified verification mechanism. "Unmodified" cannot be asserted by a BATS test without a known baseline (a checksum, a reference copy, or a git-based diff against a known commit). The `test-cache-mechanism-retired.bats` file described in the task description covers deletion and content-absence assertions, but the description does not mention any assertion over historical records.

In practice this constraint is enforced by code review (the PR diff shows no changes to those directories) or by `git diff --name-only` output. A BATS unit test cannot reliably assert "these files have the same content as before the task ran" because the "before" baseline is not available to the test at runtime.

As written, no test writer can generate an automated test from this expectation.

## Recommendation

Either:
- Remove this expectation from the test expectations list and note it as a code-review constraint (PR reviewer verifies the diff touches no files under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`), or
- Convert it to a structural assertion: "The test suite asserts that no files matching `docs/qrspi/2026-04-29-v0.4-bundle/**` or `docs/superpowers/**` appear in a `git status --porcelain` check performed after the task changes are applied."
