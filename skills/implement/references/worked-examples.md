# Worked Examples — Wave Execution and Quick Fix

Read this file for worked examples illustrating the per-task flow. Not load-bearing prose — illustrative only.

## Worked Example — Wave Execution (Full Pipeline)

Given the Worked Example in `parallelize/SKILL.md`:

**Pre-flight — baseline.** Implement creates `.worktrees/user-auth/baseline/` from the feature branch tip, runs baseline tests, deletes the worktree. Assume baseline passes (otherwise the Auto-fix path injects `task-00` and runs the per-task flow for it in isolation before Wave 1).

**Wave 1.** Implement reads the Branch Map. Tasks 1 and 2 both have `Base = feature branch tip` and are file-disjoint. Resolve `feature branch tip` to the current tip of `qrspi/user-auth/main`, create worktrees `.worktrees/user-auth/task-01/` and `.worktrees/user-auth/task-02/` from that commit, dispatch both implementer subagents concurrently (Agent tool; each with its task's worktree path named in the prompt). When task-01's implementer returns DONE, main chat dispatches task-01's reviewer set in parallel; same for task-02. Wait for both per-task flows to reach a terminal status.

**Stage commit creation.** Both Wave 1 tasks now in terminal state. Implement sees Wave 2 needs `stage-after-W1`. Create branch `qrspi/user-auth/stage-after-W1` by merging task-01 and task-02 tips. (Composition is documented in `parallelization.md` § Stage Commits.)

**Wave 2 and Wave 3 (concurrent).** Task 3's `Base = stage-after-W1` resolves to the freshly-created stage commit. Task 4's `Base = task-01 tip` resolves to the current tip of `qrspi/user-auth/task-01`. Wave 2 and Wave 3 dispatch concurrently because their dependencies are satisfied (no inter-Wave file overlap, no logical dependency on each other) — create both worktrees, dispatch both implementer subagents concurrently, run their per-task flows, wait for both terminal statuses.

**Batch gate.** All four tasks are now in terminal state. Present the batch gate; on "continue," invoke the next route step (Integrate).

## Worked Example — Quick Fix Single Task

Quick-fix run with one task at `tasks/task-01.md`:

**Pre-flight — baseline.** Implement creates `.worktrees/{slug}/baseline/` from the feature branch tip, runs baseline tests, deletes the worktree. Assume baseline passes.

**Single dispatch.** Create worktree `.worktrees/{slug}/task-01/` forked from the feature branch tip, dispatch the implementer subagent for task-01 (Agent tool; with the worktree path named in the prompt). On DONE, dispatch the correctness reviewer set in parallel; on issues, dispatch implementer-fix subagent and re-run reviewers (up to 3 cycles). Wait for terminal status.

**Batch gate.** Task is in terminal state. Present the batch gate; on "continue," invoke the next route step (Test).
