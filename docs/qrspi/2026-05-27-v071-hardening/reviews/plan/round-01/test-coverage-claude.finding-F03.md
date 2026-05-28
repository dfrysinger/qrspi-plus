# Finding F03: Task 2 — "Simulates fresh clone" test setup mechanism is unspecified, making the expectation non-deterministic

**Artifact:** plan.md
**Task:** Task 2 (G2 — gitignore scratch commit-message file)
**Category:** Test Expectation Quality
**Severity:** advisory

## Problem

The third test expectation is:

> "The assertion holds in a context that simulates a fresh clone (no `.git/info/exclude` entry for the scratch path)."

This names the desired precondition but does not describe how the test harness creates it. The existing `.git/info/exclude` file on the developer's workstation almost certainly already excludes `.qrspi-commit-msg.txt` (the description says the current protection relies on this entry). A test that simply runs `git add -A` in the live repo working directory will exercise the `.gitignore` path AND the `.git/info/exclude` path simultaneously, making it impossible to tell which mechanism is doing the work.

Without an explicit test-harness action — such as:
- Initializing a temporary git repo that has no `.git/info/exclude` entry for the scratch path, OR
- Running the assertion after temporarily renaming/removing the `.git/info/exclude` entry for that path, OR
- Running the assertion in a CI environment that performs a fresh clone with no per-clone exclude setup

…the expectation is not deterministically falsifiable. An implementation that adds the entry only to `.git/info/exclude` (not to `.gitignore`) would still pass the test on the developer's machine.

## Recommendation

Make the setup mechanism concrete:

- "The test creates a temporary directory, initializes a new `git init` repo with no `.git/info/exclude` content, creates a scratch file at `.qrspi-commit-msg.txt`, runs `git add -A`, and asserts the scratch path is absent from the staged index."

This makes the "fresh clone, no per-clone exclude" precondition explicit and repeatable.
