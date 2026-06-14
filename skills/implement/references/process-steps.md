# Process Steps — full per-step procedure (full pipeline + quick fix)

This file is `!cat`-included under the `## Process Steps` H2 in `skills/implement/SKILL.md`. The order matters: baseline tests run **before** per-task worktree creation so that a baseline failure can inject `task-00` (full pipeline) or be classified as the first quick-fix task without violating the re-fork prohibition.

Branch on mode (derived from `config.md.route` per § Overview) at the start. Both modes share Steps 1–5 with mode-conditional details; Step 6 onward differs.

1. **Read inputs.** Full pipeline: read `parallelization.md` (Branch Map organized into `### Wave N` sub-sections + Stage Commits; if a `## Runtime Adjustments` section exists from a prior session, load its overrides into the in-memory base-resolution table). Quick fix: read every `tasks/*.md` OR every `fixes/{type}-round-NN/*.md` per the dispatch shape — see § Batch Gate Definition for the two quick-fix main-dispatch shapes plus the isolated baseline-fix dispatch event (`references/fix-task-routing.md` for fix-task dispatch specifics). Each dispatch reads one set, not both.

2. **Ask phase config** (`review_depth`, `review_mode`), write to `config.md` (skip on fix-task dispatches — reuse existing values).

3. **Create feature branch** `qrspi/{slug}/main` from the current branch if it does not exist (first phase only in full pipeline; first batch only in quick fix). Naming it `/main` (not bare `qrspi/{slug}`) is required so task branches `qrspi/{slug}/task-NN` can coexist as namespace siblings.

4. **Run baseline tests** in a single throwaway worktree at `.worktrees/{slug}/baseline/` forked from the feature branch tip. **Resume precondition:** if `.worktrees/{slug}/baseline/` already exists when this step starts, delete it first — the prior baseline result is not trusted across sessions because the feature branch tip may have advanced. See § Baseline Tests for the 3 options when failures occur. **Invariant:** if the pipeline continues past this step, the baseline worktree must be gone before any per-task worktree exists.

5. **If baseline failed and the user chose Auto-fix:**
    - Delete `.worktrees/{slug}/baseline/` (per Step 4's invariant).
    - **Full pipeline:** dispatch `task-00` first, in isolation. Write the `task-00` Branch Map row and the `## Runtime Adjustments` section to `parallelization.md` (see § Baseline Tests Auto-fix path). Create only the `task-00` worktree at `.worktrees/{slug}/task-00/`, forked from feature branch tip. Run the per-task TDD + review flow (see § Per-Task Execution) for `task-00`, wait for terminal state. Once `task-00` is in terminal state, proceed to Step 6 with the in-memory resolution table now overlaying Runtime Adjustments (so dependents resolve to `task-00 tip`).
    - **Quick fix:** the baseline-fix task is dispatched as its own isolated dispatch event BEFORE the originally-requested dispatch (no `parallelization.md`, no Branch Map row to append). Write `tasks/task-00.md` with `status: approved`, create the `task-00` worktree forked from feature branch tip, run the per-task flow for `task-00`, wait for terminal state. The baseline-fix dispatch's task set is `{tasks/task-00.md}` (one task). Once `task-00` is in terminal state, proceed to Step 6 to dispatch the originally-requested task set as a separate isolated dispatch event. The isolated baseline-fix dispatch auto-continues to the main dispatch with no intermediate batch gate; only the main dispatch's batch gate fires at Step 8.

5.5. **Task-count read and dynamic skip.** Run the procedure in § Implement-Entry Task-Count Read and Dynamic Skip. This step fires once per Implement entry (not on subsequent fix-round dispatches within the same phase), after the smoke check and after any baseline-fix pre-dispatch, but **before** any per-task worktree creation and before any Parallelize or Integrate dispatch. Branch on the count (`N`) per that section: N=0 halts the phase; N=1 writes the audit append and skips to the single-task per-task dispatch (Step 6), bypassing Parallelize and Integrate; N>1 writes the audit append and falls through to Step 6's normal dispatch.

6. **Dispatch tasks.**
    - **Full pipeline — for each `### Wave N` sub-section under Branch Map**, in ascending N order:
        - Resolve every task's effective base: read the Branch Map's `Base` column, then apply `## Runtime Adjustments` overrides on top.
        - Create any required `stage-after-W{N}` branch (merging the named Wave's leaves).
        - Create the per-task worktree at `.worktrees/{slug}/task-NN/`. Verify `.worktrees/` is in `.gitignore`.

          **Worktree-local exclude append (T38 worktree-local-exclude invariant).** Immediately after `git worktree add` succeeds and before dispatching the implementer subagent, append the line `.qrspi-commit-msg.txt` to `.worktrees/{slug}/task-NN/.git/info/exclude` (creating the file if it does not exist). This append happens once at worktree creation time, independent of any per-commit ordering, and satisfies the worktree-local-exclude invariant declared in `skills/implementer-protocol/SKILL.md` § Commit hygiene invariants for every commit cycle the implementer runs in this worktree. The append does not pollute the target repo's committed `.gitignore` (the exclude file is worktree-local under `.git/`).

          **Resume precondition.** Before attempting `git worktree add`, if any leftover state exists for `task-NN`, see `references/resume-preconditions.md` for the four-case classification table and the inspect-and-decide procedure.
        - Fire the wave's per-task flows concurrently — for each task, dispatch the implementer subagent (multiple Agent tool calls in a single message; each with the task's worktree path named in the prompt) per § Per-Task Execution.
        - Wait for every task in the wave to reach a terminal status (per the per-task fix loop).
        - If the next Wave needs a `stage-after-W{N}` stage commit composed from this Wave's leaves, create it now.
    - **Quick fix:** for each task in the batch (no waves):
        - Create the per-task worktree at `.worktrees/{slug}/task-NN/`, forked from feature branch tip. Verify `.worktrees/` is in `.gitignore`. Apply the same Resume precondition behavior. Apply the same **worktree-local exclude append** (T38 worktree-local-exclude invariant): immediately after `git worktree add` succeeds and before dispatching the implementer subagent, append the line `.qrspi-commit-msg.txt` to `.worktrees/{slug}/task-NN/.git/info/exclude` (creating the file if it does not exist).
        - Dispatch the implementer subagent per § Per-Task Execution (multiple in parallel if the batch has multiple fix tasks; they are file-disjoint by quick-fix construction).
        - Wait for every task to reach a terminal status.

7. **Orchestration boundary observability check (phase end, after all waves complete).** Before presenting the batch gate, run the OBC step defined in § Orchestration Boundary Observability Check (Phase-End). The OBC step is the load-bearing place to catch commit-based orchestration drift, because the stage-commit chain authored across waves is exactly where main-chat commits in the phase range would show up. If the OBC script is absent or non-executable, the orchestrator writes the `obc-script-absent:` named diagnostic under `## Dispatch defects` and halts before invocation per § Batch Gate (After All Tasks). A populated `## Dispatch defects` section halts unconditionally; a clean (byte-empty) report proceeds to Step 8.

8. When every task in the batch has reached a terminal state AND the OBC step has completed without a halt, present the batch gate (see § Batch Gate).

9. On user "continue", invoke the next route step (see § Terminal State for the routing algorithm).
