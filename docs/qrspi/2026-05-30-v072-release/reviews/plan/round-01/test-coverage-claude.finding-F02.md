---
finding_id: R1-F02
reviewer: test-coverage-claude
artifact: plan.md
task: Task 38
severity: high
change_type: correctness
---

# T38 — "Mental-replay check" is not a verifiable test expectation

## What

Task 38 (G35 Structure reviewers enforce architecture-only-in-structure
boundary) lists this Test expectation:

> Mental-replay check: a v0.7.2 `structure.md` containing a unified system
> architecture Mermaid diagram plus a top-level `## Test Architecture`
> section stitching per-goal/per-CD acceptance criteria by test type would
> not trigger a Structure scope finding under these reviewer prompts.

This is a thought experiment, not a test. There is:

- No fixture document path the Test writer should create.
- No reviewer-dispatch invocation a test harness can run against the fixture.
- No assertion on observable output ("no finding files written," "empty
  `clean.md` sentinel," "no `severity: high` row in `<reviewer_tag>.finding-*`
  files," etc.).
- No way to detect failure: a Test writer can only "mentally replay" the
  fixture, which is exactly the human-judgement loop the test phase is
  supposed to remove.

The same DoD bullet ("`agents/qrspi-structure-reviewer.md` positively instructs
the reviewer to recognize a unified system architecture diagram and a
top-level `## Test Architecture` section as expected Structure content while
preserving minimal artifact-quality reviewer duties") is verifiable as a grep
audit. The mental-replay expectation adds nothing that grep audits can't carry
deterministically.

## Why this is a test-coverage problem

Test criteria 4 (Test Expectation Quality) requires:
- **Observable** — describes something visible to a caller or test harness.
- **Deterministic** — the same inputs always produce the same expected output.
- **Falsifiable** — there exists an implementation that would fail this
  expectation.

The mental-replay check fails all three: no observable output, no
deterministic recipe, no failing implementation a Test writer could write to
RED.

## Falsifiable alternative

Either:

1. Replace the mental-replay bullet with a concrete fixture + dispatch
   recipe: "Create a fixture `structure.md` at <path> containing the named
   Mermaid block and `## Test Architecture` section; dispatch
   `agents/qrspi-structure-scope-reviewer.md` against the fixture; assert the
   reviewer writes only a `<reviewer_tag>.clean.md` sentinel and no
   `<reviewer_tag>.finding-F*.md` files in the round directory." OR
2. Remove the bullet — the grep audits already cover the prose contract, and
   the structure-reviewer dispatch coverage belongs to a broader Phase-1
   acceptance test, not a per-task expectation.

## References

- plan.md ### Task 38 — Test expectations bullet 5.
- Test criteria 4 (Test Expectation Quality) from this reviewer's dispatch
  contract.
