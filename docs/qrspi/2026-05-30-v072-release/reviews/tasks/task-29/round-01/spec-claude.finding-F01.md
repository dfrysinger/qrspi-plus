---
finding_id: F01
severity: medium
change_type: spec
file: tests/lint/test-design-altitude-boundary-include.bats
---

# Lint test does not enforce the positional ("immediately after") requirement from the task spec

## What the spec says

task-29.md ## Scope (In) explicitly requires:

> Create `tests/lint/test-design-altitude-boundary-include.bats` asserting that
> `agents/qrspi-design-scope-reviewer.md` contains the literal
> `!cat skills/_shared/design-altitude-boundary.md` directive **on the line
> immediately after the Step 1 Read citation introducer prose**, and that
> `skills/design/owns-defers.md` contains the same literal directive **in place
> of the previous inline contract body**.

DoD reinforces:

> `tests/lint/test-design-altitude-boundary-include.bats` exists and asserts the
> literal `!cat skills/_shared/design-altitude-boundary.md` directive is present
> in both consumer files **at the canonical insertion points**; removal of
> either directive fails the lint with a file-and-directive-naming diagnostic.

The test expectations section likewise lists "Ordering inspection confirms the
Design scope-reviewer introducer prose appears immediately after the Step 1 Read
citation and immediately before the `!cat` directive."

## What was implemented

`tests/lint/test-design-altitude-boundary-include.bats` has two cases that only
run a presence-only `grep -qF` for the directive string in each consumer file
(lines 21–35 of the new test). It does not assert:

1. that the directive in `agents/qrspi-design-scope-reviewer.md` is on the line
   *immediately after* the introducer prose `The contract you just read carries
   the following allowances and deferrals; restated here so they are present in
   your immediate reasoning context:`, and
2. that the introducer prose itself appears immediately after the Step 1 Read
   citation line, and
3. that `skills/design/owns-defers.md` carries the directive *in place of the
   previous inline contract body* (i.e., that no inline OWNS/DEFERS bullets
   remain alongside the `!cat`).

Drift such as someone re-inlining the OWNS/DEFERS bullets next to the `!cat`,
or moving the introducer prose away from Step 1's Read citation, would silently
pass the current lint while violating the task's canonical-insertion-point
contract.

## Why this is a defect (not a nit)

The task is the lint guard for a single-source boundary. Its acceptance language
is unusually explicit ("on the line immediately after", "at the canonical
insertion points", "in place of the previous inline contract body"); a
presence-only grep is materially weaker than what was specified. Future
T30/T37 work cited as downstream consumers ("Blocks: T30, T37") relies on this
guard catching insertion-point drift.

## Suggested fix

Strengthen the two `@test` cases (or add a third) to assert ordering, e.g.:

- Locate the line number of `Read \`skills/design/owns-defers.md\`` in
  `agents/qrspi-design-scope-reviewer.md`; assert the introducer prose appears
  on the next non-blank line and the `!cat` directive on the line immediately
  after the introducer (allowing for one blank line is acceptable if the spec
  is read leniently, but adjacency must be checked, not just presence).
- For `skills/design/owns-defers.md`, assert that no `### Design OWNS` /
  `### Design DEFERS` headings remain inline (i.e., the previous inline body
  was actually replaced, not merely augmented), in addition to the `!cat`
  presence check.

Both assertions must emit a diagnostic naming the violating file and the
missing/misplaced directive when they fail, matching the existing diagnostic
style.

## Verification anchor

- Subject: `tests/lint/test-design-altitude-boundary-include.bats` lines 21–35
- Spec: `tasks/task-29.md` Scope (In) bullet 4; DoD bullet 8; Test
  expectations bullet 3.
