---
finding_id: R1-F04
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L942-L956]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T32's test expectations include "The BATS pin asserts the atomicity contract under a simulated sub-subagent failure: `plan.md` retains `status: draft`, no partial `tasks/task-NN.md` files from the failed dispatch survive, and a diagnostic identifying the failed dispatch is surfaced." However, the description and the test expectations for the atomicity contract specify cleanup of partial files only "from the failed dispatch" — not partial files from sub-subagent dispatches that succeeded before the failure.

In a parallel N=3 fan-out where sub-subagents for tasks 1 and 2 succeed and task 3 fails, the atomicity contract as described says "no partial `tasks/task-NN.md` files from the failed dispatch survive." This language may be read as: `tasks/task-03.md` (the failed one) is cleaned up, but `tasks/task-01.md` and `tasks/task-02.md` (which succeeded before the failure) are left on disk. The result is a partially-split plan state: `plan.md` retains `status: draft` (good), but two task files already exist on disk for a draft plan, which is an inconsistent partial state.

The T31 test expectation "the section preserves the main-chat transactional steps in order: collect confirmations, verify file count, rewrite `plan.md` to overview-only, capture `phase_start_commit:`, write `status: approved`" implies that all task files should be cleaned up on failure, not just the one from the failed dispatch. But this is not explicitly tested: no test expectation states "when any sub-subagent fails, ALL previously-written `tasks/task-NN.md` files from this split run are removed, leaving the task directory clean."

This is a partial-state-on-failure pattern: the system leaves a mixed state (some task files present, plan in draft, no approval) that a subsequent re-run may not safely handle (the re-run's file-count verification step might see existing files and consider the fan-out partially complete when it should start fresh).

The fix is to strengthen the atomicity contract test expectation in T32: "When any sub-subagent fails during the N>=3 fan-out, ALL `tasks/task-NN.md` files written during the current fan-out run are removed, not only the file from the failed dispatch, before the loud diagnostic is surfaced."
