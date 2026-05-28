---
finding_id: F03
reviewer: goal-traceability-claude
round: 2
severity: low
artifact: plan.md
section: "Task 8: Retire prompt-cache mechanism from dispatcher, skill, and test infrastructure"
checklist_item: "1. Forward Trace — Goals to Tasks (G7a: plan-authored test expectations lack automated test backing)"
---

# F03 — Task 8 test expectations have no backing BATS test file and silently drop the test-writer-first protocol

## Problem

The round-2 change to Task 8 removed `tests/unit/test-cache-mechanism-retired.bats`
from the target files list and removed the "Dispatch order: test-writer first,
implementer second (RED-verification gate between)" clause from the description.
The task's `## Test Expectations` block still lists specific verifiable assertions
(including one labeled "a path-scope assertion in the modify-pass verifies…"), but
there is no test file for the test writer to write, and no RED gate is established.

## What changed in round 2

**Round-1 target files included:**
```
tests/unit/test-cache-mechanism-retired.bats` (create)
```

**Round-1 description included:**
> A new structural test file asserts the post-retirement invariants (deleted files
> absent, patterns absent from modified files); these assertions fail RED against
> current state and pass GREEN after all deletions and removals land.
> Dispatch order: test-writer first, implementer second (RED-verification gate between).

**Round-2 target files:** `test-cache-mechanism-retired.bats` removed entirely.

**Round-2 description:** "Deletions and removals are a mechanical sweep with no new
design surface; CI-green is the acceptance gate per Design DKR8."

## Why this matters for goal traceability

The plan-authored `## Test Expectations` block for Task 8 still includes assertions
that imply automated test implementations:

- "filesystem absence" post-conditions for four deleted files
- "`scripts/run-third-party-llm.sh` contains no `cache_control` key emission logic"
- "`tests/acceptance/…` still contains the G6 assertions added by Task 7"
- "The `git diff --name-only` output for the Task 8 commit does not list any path
  under `docs/qrspi/2026-04-29-v0.4-bundle/` …; **a path-scope assertion in the
  modify-pass verifies** historical run-record directories are not touched"

The last item explicitly says "a path-scope assertion … verifies" — naming an
automated assertion — but there is no file for the test writer to implement it in.

Meanwhile, all other tasks in the plan carry "Dispatch order: test-writer first,
implementer second (RED-verification gate between)." Task 8's drop of this clause
is not flagged or explained in the task spec itself (the `## Reviewer Findings Set
Aside` section explains the DKR8 rationale at the plan level, but the individual task
spec gives no cue).

## Relationship to design DKR8

`design.md` DKR8 states: "G7a has no design surface. Plan enumerates the exact line
ranges and produces a single deletion task … Validated by CI-green per Design DKR8."

This finding does not challenge DKR8. CI-green is an acceptable acceptance gate for
a mechanical deletion. The issue is that the plan's `## Test Expectations` block uses
assertion-style language ("a path-scope assertion … verifies") that a dispatched
test writer would interpret as "write this in a BATS test file" — but there is no
file to write it in, and the task spec gives no indication that these are manual
inspection checkpoints rather than BATS assertions.

## Suggested resolution

Two acceptable resolutions (either suffices):

**Option A — keep no BATS file, relabel expectations as verification checklist:**
Change the `## Test Expectations` header to `## Verification Checklist` (or add a
`<!-- manual verification -->` callout at the top of the block) to make clear that
these are implementer-side inspection items, not items the test writer encodes in a
BATS suite. Remove the phrase "a path-scope assertion in the modify-pass verifies"
and replace with "the implementer manually confirms that no path under…".

**Option B — restore a minimal structural test file:**
Restore `tests/unit/test-cache-mechanism-retired.bats` with the file-absence
assertions and the pattern-absence assertions. These can be written to fail RED
against the current state (the files exist; the pattern exists) and pass GREEN
after deletion — restoring the TDD gate while satisfying the mechanical-deletion
spirit of DKR8.

The finding is low severity because DKR8 makes the intent clear at the plan level
and the mechanical deletion is unlikely to be mis-implemented. The gap is primarily
a protocol-consistency concern: a test writer dispatched to Task 8 has no clear
contract for what to write (or not write).
