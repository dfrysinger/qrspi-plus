---
id: F03
reviewer: silent-failure-claude
round: 1
artifact: plan.md
category: PARTIAL_STATE
severity: medium
tasks_affected: [Task 7, Task 8]
goal_ids: [G6, G7a]
---

# F03 — Tasks 7 and 8 co-modify the same acceptance test file; Task 8 expectations don't pin preservation of Task 7 additions

## What the plan says

Two tasks write to `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`:

**Task 7** (target files):

> "`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify)"
> The acceptance test gains two new end-to-end host-detection assertions: one for the Copilot CLI
> path and one for the Claude Code path.

**Task 8** (target files, description):

> "`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify)" — "loses the `SPIKE`
> export pointing at the deleted spike report and the two `run_pin` invocations for the deleted
> unit suites."

The dependency chain correctly sequences Task 7 before Task 8. Task 8's description specifies
what to REMOVE from the file. However, Task 8's test expectations are:

> "`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` contains no `SPIKE` variable export
> referencing the deleted spike file and no `run_pin` invocations referencing the deleted suite
> files after modification."

This expectation is satisfied by any of the following implementations — including a destructive one:

1. Surgical removal of only the SPIKE export and the two stale `run_pin` lines (correct).
2. Reverting the file to its pre-Task-7 state and removing the stale lines (incorrect — removes the
   G6 E2E coverage that Task 7 added, but the Task 8 expectation would still PASS because the
   SPIKE export and stale `run_pin` lines are also absent in that state).

## Why this is a partial-state silent failure

If implementation 2 happens, the G6 acceptance coverage (the two new host-detection assertions)
disappears from the test suite. CI does not flag this because:

- The Task 7 test expectations apply to Task 7's implementation round, not to later states of the
  file.
- Task 8's test expectations verify *absence* of old content but not *presence* of new content
  added by Task 7.
- There is no structural assertion in either task that pins: "after both tasks are applied, the
  acceptance test contains the G6 E2E assertions AND lacks the SPIKE/run_pin content."

The result is a **silent regression in test coverage**: the G6 host-detection runtime behavior
goes unverified by the acceptance suite, and the Phase 1 acceptance criteria claim
"Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts" — but
the test that was supposed to verify this has quietly vanished.

## What needs to be added

Task 8's test expectations must add a positive-presence assertion for the Task 7 additions:

> "`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` contains the G6 host-detection
> assertions added by Task 7: the Copilot CLI transport-selection assertion and the Claude Code
> transport-selection assertion are both present after the Task 8 modifications are applied."

Alternatively, the co-modification risk can be eliminated by refactoring: Task 8 modifies only
files that are NOT also modified by Task 7 for the acceptance test section. But since the
dependency structure requires sequential editing of the same file, the simplest fix is to add
explicit preservation assertions to Task 8's test expectations so that the final state of the
acceptance test is pinned in both dimensions — what was removed AND what was preserved.
