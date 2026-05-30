---
reviewer: code-quality-claude
task: 2
round: 1
finding: F02
severity: low
area: cleanliness
status: open
---

# F02 — Stale transitional comment and redundant pre-test expectation block

## Location

`tests/unit/test-commit-hygiene-invariants.bats` — new lines added in round-01 diff.

## Issue A — Stale "RED until" comment

```bats
# =============================================================================
# G2 committed-gitignore invariant: .qrspi-commit-msg.txt in committed
# root .gitignore closes the fresh-clone / fresh-worktree staging gap.
#
# These tests are RED until the implementer adds the entry to .gitignore.   ← stale
# =============================================================================
```

This comment was written during the test-writer phase (before the implementation),
when the tests were intentionally red. The implementer has now added the `.gitignore`
entry, so the comment is factually false for anyone reading the file in its current
committed state. Stale transitional comments are misleading — a future reader may
infer the feature is unfinished.

**Suggested fix:** Remove the stale line entirely (the section header already
provides sufficient orientation), or replace it with a note that the tests go green
once the `.gitignore` entry is present (present tense).

---

## Issue B — Redundant "Test expectation:" pre-comments

```bats
# Test expectation: The string `.qrspi-commit-msg.txt` appears verbatim in the
# content of the committed root `.gitignore` file
@test "[T02-G2-hygiene] committed root .gitignore contains .qrspi-commit-msg.txt verbatim" {
```

And:

```bats
# Test expectation: When a scratch commit-message file is present on disk and
# `git add -A` is executed in a simulated commit flow, the scratch file path
# does not appear in the resulting staged index.
# Test expectation: The fresh-clone simulation uses a temporary scratch git
# directory created via `mktemp -d` + `git init` with no `.git/info/exclude`
# entry for the scratch path; the test asserts the staged-index behavior
# independently of any per-clone exclude file.
@test "[T02-G2-hygiene] git add -A does not stage scratch file on fresh-clone simulation (gitignore-only, no per-clone exclude)" {
```

These block comments are verbatim copies of the task-spec test-expectation bullet
points. Per the cleanliness criteria, comments should orient the reader or explain a
non-obvious WHY — not restate what the test name and test body already make clear.
The first comment adds no information that the `@test` name doesn't already contain.
The second is longer but still substantially restates the test name.

The test name `(gitignore-only, no per-clone exclude)` already captures the
key "WHY" — that the isolation is from `.gitignore` not from a per-clone exclude.
The inline `# Pre-condition:` and `# Simulate the implementer disk state:` comments
inside the test body do a better job of orienting the reader step-by-step.

**Suggested fix:** Remove the pre-test block comments (the test names and inline
comments are sufficient). If a multi-line orientation is desired for the second test,
reduce it to the non-obvious WHY: that the fixture intentionally omits any
`.git/info/exclude` entry so that only the committed `.gitignore` provides protection.
