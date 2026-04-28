---
name: implement
description: Per-phase implementation orchestrator. In full pipeline mode, resolves symbolic bases from parallelization.md to concrete commits, creates worktrees and stage commits, runs baseline tests, dispatches per-task orchestrator subagents per the wave schedule, presents the batch gate, and routes to the next route step (typically Integrate). In quick-fix mode, dispatches the single task (or a fix-task batch from fixes/{type}-round-NN/) through per-task orchestrator subagents, presents the batch gate (with quick-fix-mode menu), and routes to Test.
---

# Implement (QRSPI Step 8)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Implement skill to run the per-phase implementation loop."

## Overview

Runtime owner of per-phase implementation. Mode is derived from `config.md.route` (`route` is the authoritative pipeline contract per `using-qrspi/SKILL.md` § Config File): **full pipeline** if `parallelize` precedes `implement` in the route; **quick fix** otherwise. Responsibilities split by mode:

- **Full pipeline** — owns the `Parallelize → Implement(per-phase loop) → Integrate` segment. Reads the symbolic Branch Map from `parallelization.md`, resolves each `Base` to a concrete commit at runtime (creating stage commits on demand), creates worktrees, runs baseline tests, dispatches a per-task orchestrator subagent for every task in the current phase following the wave schedule, presents the batch gate when every task has reached a terminal state, and only then invokes the next route step (typically Integrate).
- **Quick fix** — owns the single-batch `Plan → Implement → Test` segment. No `parallelization.md`, no waves, no stage commits, no branch model. Creates a feature branch and one worktree per task, runs baseline tests, dispatches a per-task orchestrator subagent for each task in the batch (one task initially, possibly multiple fix tasks under `fixes/{type}-round-NN/`), presents the quick-fix batch gate, and routes to Test.

The per-task orchestrator subagent is the layer-2 subagent that runs `templates/per-task-orchestrator.md`. It in turn dispatches the layer-3 implementer subagent (`templates/implementer.md`) and reviewer subagents (`templates/correctness/*`, `templates/thoroughness/*`). The Implement skill (this file) is layer 1; it never runs TDD or reviewers itself.

## Iron Law

```
NO TASK DISPATCH WITHOUT APPROVED INPUTS
```

Mode-conditional definition of "approved inputs":

- **Full pipeline:** `parallelization.md` must exist with `status: approved` (the Branch Map is the dispatch contract).
- **Quick fix:** every `tasks/*.md` (or `fixes/{type}-round-NN/*.md`) targeted by this run must have `status: approved` (the task spec is the dispatch contract).

If the required input is missing or not approved, refuse to run and tell the user which artifact is needed.

## Implement Is the Per-Phase Orchestration Loop

```
IMPLEMENT FIRES ONE PER-TASK ORCHESTRATOR SUBAGENT PER TASK,
THEN ROUTES TO THE NEXT STEP EXACTLY ONCE PER PHASE.
```

### Batch Gate Definition (Release Conditions)

The batch gate is the human gate Implement presents after every task in the current batch has reached one of the following terminal states:

- (a) **Clean** — completed per-task orchestration with no unresolved reviewer findings
- (b) **Accepted-with-issues** — completed per-task orchestration with reviewer findings that the user explicitly accepted (logged but not blocking)
- (c) **Skipped-by-user** — explicitly skipped at the user's request before or during the loop

All N tasks must be in (a), (b), or (c) before the batch gate fires. The batch gate is the only point at which Implement relinquishes control. The user's decision at the batch gate (continue / re-run reviews / fix issues / stop) is what releases the loop and routes to the next step.

The "current batch" is mode-specific:

- **Full pipeline:** every task in `parallelization.md` for the current phase.
- **Quick fix:** the tasks targeted by the **main dispatch event** for this batch. Two main-dispatch shapes that get a batch gate:
  - **Normal entry:** every originally-requested `tasks/*.md` (typically one task; **excludes** any runtime-generated `tasks/task-00*.md` baseline-fix singletons, which are pre-dispatched separately per the next paragraph)
  - **Fix-task dispatch:** every `fixes/{type}-round-NN/*.md` for the round that triggered this dispatch (see `references/fix-task-routing.md`)

  Each main dispatch reads exactly one set, not both. The batch gate fires once, after the main dispatch's tasks reach terminal state.

  **Pre-dispatch events that do NOT have their own batch gate:** the isolated baseline-fix dispatch (a singleton `{tasks/task-00.md}` or `task-00b.md`, etc.) runs as a separate dispatch event BEFORE the main dispatch when baseline auto-fix is triggered (see Baseline Tests § Auto-fix and Process Steps Step 5). It auto-continues to the main dispatch with no intermediate batch gate; only the main dispatch's batch gate fires (at Step 7). The baseline-fix `task-00.md` still must satisfy input-approval gating (Iron Law / HARD-GATE / Artifact Gating); these abbreviate the eligible inputs as "tasks/*.md or fixes/...", and `tasks/task-00*.md` is covered by the `tasks/` clause as a strict subset.

**Why:** without the (a)/(b)/(c) gate, the model rationalizes "this one task is done, just integrate it" and per-task integration breaks the cross-task review's premise. Implement does not advance to Integrate (or Test) task-by-task.

### State Transition Contract

Skills do not write `state.json` directly — the hook layer owns it. State lives only in the artifact dir's `.qrspi/state.json`. Worktrees do not contain `.qrspi/` directories. See `using-qrspi/SKILL.md` § Hook-Managed State.

Behavior contract Implement relies on:

- While Implement is mid-batch: `state.json` `current_step` stays at `implement`. There is no `active_task` field in the new schema — to verify mid-batch state, cross-check the full batch task set per the next bullet.
- After the batch gate releases and Implement invokes the next route step: `current_step` advances to whichever step is next in `config.md` route (typically `integrate` in full pipeline, `test` in quick fix).

Readers verifying `current_step` mid-batch should cross-check the in-flight task set against `parallelization.md` (full) or against the task set for the in-flight quick-fix dispatch event — every originally-requested `tasks/*.md`, every `fixes/{type}-round-NN/*.md`, or the singleton `{tasks/task-00*.md}` for an in-flight isolated baseline-fix dispatch event (see § Batch Gate Definition for the two quick-fix main-dispatch shapes plus the isolated baseline-fix dispatch event). If a hook does not yet realize a transition asserted above, file a hook bug; do not work around it by writing state directly.

## Artifact Gating

Required inputs depend on mode (derived from `config.md.route` per § Overview):

**Full pipeline — required inputs:**

- `parallelization.md` with `status: approved`
- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md` (for fix-task routing)
- `design.md` with `status: approved` (phase definitions)
- `config.md`

**Quick fix — required inputs:**

- `plan.md` with `status: approved`
- `tasks/*.md` (typically one) or `fixes/{type}-round-NN/*.md` (for fix-task routing)
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `config.md`

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Same procedure as Parallelize. See `using-qrspi/SKILL.md` § Config Validation Procedure. Implement validates `route`, `codex_reviews`, and (after the Phase-Level Configuration step has run for this phase) `review_depth` and `review_mode`. Implement does not validate `pipeline` — that field is informational per the Config File contract; mode is derived from `route` (see § Overview).

<HARD-GATE>
Do NOT dispatch per-task orchestrator subagents without the mode-appropriate approved inputs (full: `parallelization.md`; quick: approved `tasks/*.md` or approved `fixes/{type}-round-NN/*.md` per the dispatch shape — see § Batch Gate Definition for the two quick-fix main-dispatch shapes plus the isolated baseline-fix dispatch event).
Do NOT dispatch parallel tasks (full pipeline) that touch overlapping files (re-verify against the Branch Map at runtime — `tasks/*.md` may have been edited after Parallelize approval).
Do NOT create worktrees on main/master without a feature branch.
Do NOT advance to the next route step until every task is in one of the three terminal states (clean / accepted-with-issues / skipped-by-user) defined in "Batch Gate Definition (Release Conditions)" above.
</HARD-GATE>

## Phase-Level Configuration (Runtime)

`review_depth` and `review_mode` are runtime concerns owned by Implement. At the start of each Implement run (per phase in full pipeline; per quick-fix batch entry in quick mode), ask the user:

1. **Review depth:** "Quick (4 correctness reviewers) or Deep (correctness + thoroughness, all 8 reviewers)?"
2. **Review mode:** "Single round or Loop until clean?"

Write choices to `config.md` as `review_depth` and `review_mode`. Fix-task dispatches reuse the same settings — do not re-ask. Source of truth is always `config.md`.

## Branch Model — Runtime Resolution (Full Pipeline)

In full pipeline mode, Implement consumes the symbolic Branch Map from `parallelization.md` (see `parallelize/SKILL.md` § Branch Model). At runtime, Implement resolves each `Base` value as follows:

| Symbolic base | Runtime resolution |
|---------------|--------------------|
| `feature branch tip` | The current tip of `qrspi/{slug}/main` |
| `task-NN tip` | The current tip of `qrspi/{slug}/task-NN` (must already exist before forking — enforce wave ordering) |
| `stage-after-G{N}` | A new branch `qrspi/{slug}/stage-after-G{N}` created by merging the tips of every task in Group N (composition listed in `parallelization.md` § Stage Commits). Create on demand, before forking any task whose `Base` names it. |
| `task-00 tip` | The current tip of `qrspi/{slug}/task-00` (only valid after baseline-fix injection — see "Baseline Tests" below) |

**Stage commit creation order:** walk the Branch Map in dispatch-wave order. Before starting a wave, verify every `stage-after-G{N}` referenced by any task in that wave exists; if not, create it from the named composition. Stage branches are scratch infrastructure — Integrate deletes them after merging the leaves (see `integrate/SKILL.md` § Merge Strategy).

**Re-fork prohibition.** Once a task branch exists, it is canonical. Per-task orchestrator subagents on fix-round dispatches reuse the existing branch and add commits. Do not silently re-fork.

**Why:** downstream branches that descend from a re-forked task branch would be invalidated, and the model will helpfully "fix divergence" by re-forking unless explicitly stopped. Re-forks happen only at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset.

In quick fix mode, there is no Branch Map. Each task forks directly from the feature branch tip into its own worktree. The re-fork prohibition still applies (a fix-round on the same task reuses its existing branch).

## Subagent Permissions (Hook-Governed)

Subagent containment is enforced by the QRSPI `pre-tool-use` hook (target-based asymmetric model — see `using-qrspi/SKILL.md` § How worktree enforcement works). The hook blocks any subagent Write/Edit/Bash whose target falls outside `.worktrees/{slug}/(task-NN[a-z]?|baseline)/` (the `[a-z]?` allows Plan-induced task splits like `task-07a`/`task-07b` — F-19). No per-worktree `.claude/settings.json` file is required.

**Recommended:** run sessions with `--dangerously-skip-permissions` enabled — the hook is the security wall, so per-tool approval prompts are no longer needed and would only stall subagents.

## Process Steps

The order matters: baseline tests run **before** per-task worktree creation so that a baseline failure can inject `task-00` (full pipeline) or be classified as the first quick-fix task without violating the re-fork prohibition. If worktrees were created first, dependent task branches (full pipeline) would already be forked from the wrong base.

Branch on mode (derived from `config.md.route` per § Overview) at the start. Both modes share Steps 1–5 with mode-conditional details; Step 6 onward differs.

1. **Read inputs.** Full pipeline: read `parallelization.md` (Branch Map + Stage Commits + Execution Order narrative; if a `## Runtime Adjustments` section exists from a prior session, load its overrides into the in-memory base-resolution table). Quick fix: read every `tasks/*.md` OR every `fixes/{type}-round-NN/*.md` per the dispatch shape — see § Batch Gate Definition for the two quick-fix main-dispatch shapes plus the isolated baseline-fix dispatch event (`references/fix-task-routing.md` for fix-task dispatch specifics). Each dispatch reads one set, not both.
2. **Ask phase config** (`review_depth`, `review_mode`), write to `config.md` (skip on fix-task dispatches — reuse existing values).
3. **Create feature branch** `qrspi/{slug}/main` from the current branch if it does not exist (first phase only in full pipeline; first batch only in quick fix). Naming it `/main` (not bare `qrspi/{slug}`) is required so task branches `qrspi/{slug}/task-NN` can coexist as namespace siblings — see Branch Model in `parallelize/SKILL.md` § F-14 note.
4. **Run baseline tests** in a single throwaway worktree at `.worktrees/{slug}/baseline/` forked from the feature branch tip. **Resume precondition:** if `.worktrees/{slug}/baseline/` already exists when this step starts, delete it first — the prior baseline result is not trusted across sessions because the feature branch tip may have advanced. (One check is sufficient in full pipeline: every Group 1 task forks from this same commit, so per-task baselines would be identical; downstream-group bases derive from task work that hasn't happened yet and is validated by per-task reviewers. In quick fix the same logic holds trivially — every task forks from the feature branch tip.) See "Baseline Tests" below for the 3 options when failures occur. **Invariant:** if the pipeline continues past this step, the baseline worktree must be gone before any per-task worktree exists.
5. **If baseline failed and the user chose Auto-fix:**
    - Delete `.worktrees/{slug}/baseline/` (per Step 4's invariant).
    - **Full pipeline:** dispatch `task-00` first, in isolation. Write the `task-00` Branch Map row and the `## Runtime Adjustments` section to `parallelization.md` (see "Baseline Tests" Auto-fix path). Create only the `task-00` worktree at `.worktrees/{slug}/task-00/`, forked from feature branch tip. Dispatch the `task-00` per-task orchestrator subagent, wait for terminal state. Once `task-00` is in terminal state, proceed to Step 6 with the in-memory resolution table now overlaying Runtime Adjustments (so dependents resolve to `task-00 tip`).
    - **Quick fix:** the baseline-fix task is dispatched as its own isolated dispatch event BEFORE the originally-requested dispatch (no `parallelization.md`, no Branch Map row to append). Write `tasks/task-00.md` with `status: approved`, create the `task-00` worktree forked from feature branch tip, dispatch its per-task orchestrator subagent, wait for terminal state. The baseline-fix dispatch's task set is `{tasks/task-00.md}` (one task). Once `task-00` is in terminal state, proceed to Step 6 to dispatch the originally-requested task set as a separate isolated dispatch event — either the originally-requested `tasks/*.md` (normal entry, **excluding** the just-written `tasks/task-00*.md` baseline-fix singleton — the main dispatch reads only the originally-requested files) or `fixes/{type}-round-NN/*.md` (fix-task dispatch). Each dispatch event reads exactly one set; the baseline fix and the main dispatch are separate events, not a merged batch. (Note: in this skill, "batch" = the full set of tasks gated together at the human batch gate; "dispatch event" = one invocation of per-task-orchestrator subagents reading one task set. The isolated baseline-fix dispatch is its own dispatch event but is not a separate batch — it auto-continues to the main dispatch with no intermediate batch gate; only the main dispatch's batch gate fires at Step 7.)
6. **Dispatch tasks.**
    - **Full pipeline — for each wave** in the Execution Order, in order:
        - Resolve every task's effective base: read the Branch Map's `Base` column, then apply `## Runtime Adjustments` overrides on top.
        - Create any required `stage-after-G{N}` branch (merging the named Group's leaves).
        - Create the per-task worktree at `.worktrees/{slug}/task-NN/`. Verify `.worktrees/` is in `.gitignore`.

          **Resume precondition.** Before attempting `git worktree add`, if any leftover state exists for `task-NN` (worktree dir or branch already present), see `references/resume-preconditions.md` for the four-case classification table and the inspect-and-decide procedure. The leftover-state handling differs from the baseline worktree's silent-delete rule because the baseline worktree contains no user work, while task branches and worktrees can.
        - Fire the wave's tasks concurrently (one per-task orchestrator subagent per task; multiple Agent tool calls in parallel, each with `isolation: worktree`).
        - Wait for every task in the wave to reach a terminal status.
        - If the next wave needs a `stage-after-G{N}` stage commit composed from this wave's leaves, create it now.
    - **Quick fix:** for each task in the batch (no waves):
        - Create the per-task worktree at `.worktrees/{slug}/task-NN/`, forked from feature branch tip. Verify `.worktrees/` is in `.gitignore`. Apply the same Resume precondition behavior as full pipeline (see `references/resume-preconditions.md`).
        - Fire the per-task orchestrator subagent (multiple if the batch has multiple fix tasks; they are file-disjoint by quick-fix construction).
        - Wait for every task to reach a terminal status.
7. When every task in the batch has reached a terminal state, present the batch gate (see "Batch Gate" below).
8. On user "continue", invoke the next route step (see "Terminal State" for the routing algorithm).

## Baseline Tests

Run baseline tests in a single throwaway worktree at `.worktrees/{slug}/baseline/` (forked from the feature branch tip). If `.worktrees/{slug}/baseline/` already exists from a prior halted run, delete it first; the prior result is not trusted across sessions because the feature branch tip may have changed.

If tests fail, present failure summary with 3 options:

- **(a) Auto-fix (recommended):** Inject baseline fix task `task-00` with all others depending on it. Implement writes `task-00.md` with `status: approved` in frontmatter (this is a runtime-generated task, not a Plan output, so the approval is asserted by Implement at write time so the Iron Law gate passes on dispatch). `task-00` uses `task: 0` in frontmatter and inherits the run's mode in its `pipeline` field (`pipeline: full` in full-pipeline runs, `pipeline: quick` in quick-fix runs) so the per-task orchestrator's input gating matches the artifacts that actually exist.
    - **Full pipeline:** Update `parallelization.md`:
      - Append one row to the Branch Map: `task-00 → qrspi/{slug}/task-00 (base: feature branch tip)` (without rewriting existing rows — they remain the approved record of the original plan).
      - Append a new `## Runtime Adjustments` section listing every task whose effective base changed because of the injection: `task-NN: new base = task-00 tip` (or `task-NN: new base = stage-after-G{N} re-merged on top of task-00 tip`, when the original base was a stage commit). This section is informational and does not change `status: approved` — it is the persistent record of Implement's runtime base-resolution decisions, so a fresh agent reading `parallelization.md` after a session restart can rebuild the resolution table without guessing.
      - On every subsequent dispatch in this run, Implement resolves bases by reading the Branch Map first, then applying `## Runtime Adjustments` overrides on top.
      Dispatched through the per-task orchestrator subagent like any other task.

      **Repeated baseline failures (rare).** If a second baseline failure occurs in the same phase, inject `task-00b` (then `task-00c`, etc.). Append the new task as a fresh Branch Map row (`task-00b → qrspi/{slug}/task-00b (base: task-00 tip)`); under `## Runtime Adjustments`, append new override lines but do *not* duplicate the section heading. Original `task-00` row and original Runtime Adjustments lines stay intact.
    - **Quick fix:** `task-00` is dispatched as its own isolated dispatch event — no Branch Map, no `## Runtime Adjustments`. Write `tasks/task-00.md` (with `status: approved` per the top-level Auto-fix bullet) and dispatch it as a standalone event with task set `{tasks/task-00.md}`, then proceed to dispatch the originally-requested task set as a separate event reading its own set (originally-requested `tasks/*.md` for normal entry, **excluding** the runtime-written `tasks/task-00*.md` singletons; or `fixes/{type}-round-NN/*.md` for fix-task dispatch). Repeated baseline failures add `task-00b`, `task-00c`, etc., each as its own isolated dispatch event before the original. The isolated baseline-fix dispatch event auto-continues to the main dispatch with no intermediate batch gate (see Step 5 quick-fix sub-bullet for the dispatch-event-vs-batch distinction). (Quick-fix baseline-fix tasks live under `tasks/`, not `fixes/{type}-round-NN/` — Plan's `fix_type` taxonomy only covers integration/ci/test fixes; baseline-fix is not a `fix_type` class.)
- **(b) Proceed anyway:** Log failures to `reviews/baseline-failures.md`.
- **(c) Stop:** Halt the pipeline.

**Invariant — baseline worktree gone before any per-task worktree exists.** Per-option behavior:

- **(a) Auto-fix:** delete `.worktrees/{slug}/baseline/` as the first sub-step of Process Step 5, before creating the `task-00` worktree.
- **(b) Proceed anyway:** delete `.worktrees/{slug}/baseline/` immediately after writing `reviews/baseline-failures.md`, before entering Step 6.
- **(c) Stop:** no deletion required — the pipeline halts. The user can clean up `.worktrees/{slug}/baseline/` manually if they want.

## Wave Dispatch (Full Pipeline)

In full pipeline mode, dispatch tasks in the wave order Parallelize specified. For each wave:

1. Verify every task in the wave has its `Base` resolved (and any required stage commit created).
2. Mark each task `in_progress` in TodoWrite.
3. Fire all tasks in the wave concurrently (one per-task orchestrator subagent per task; multiple Agent tool calls in parallel, each with `isolation: worktree`).
4. Wait for every task in the wave to return a terminal status (DONE, DONE_WITH_CONCERNS, or unresolved-after-3-fix-cycles per `templates/per-task-orchestrator.md` § Review Fix Loop).
5. Mark each wave's tasks `completed` in TodoWrite.
6. If the next wave depends on a stage commit (`stage-after-G{N}`), create it now from the just-completed group's tips.
7. Move to the next wave.

In quick fix mode, there are no waves — Step 6 of Process Steps dispatches the entire batch concurrently (or sequentially if the user prefers; tasks are file-disjoint by quick-fix construction so concurrency is safe).

## Fix Task Routing

When handling fix tasks from integration, CI, or test failures, see `references/fix-task-routing.md`.

## Batch Gate (After All Tasks)

When every current-batch task has reached one of the terminal states defined in "Batch Gate Definition (Release Conditions)" above — **(a) clean**, **(b) accepted-with-issues**, or **(c) skipped-by-user** — present a summary:

- Which tasks passed clean (state a)
- Which tasks have unresolved issues that the user accepted (state b — issue summaries + acceptance reasons)
- Which tasks were skipped (state c — skip reason)
- Review round history per task

The menu varies by batch outcome:

**When all tasks passed clean:**

```
All tasks passed clean. Choose:
1. Re-run all reviews (confidence check)
2. Continue to next step
3. Stop
```

**When tasks have unresolved issues:**

```
{N} task(s) have unresolved issues. Choose:
1. Fix remaining issues and re-run reviews — re-enter fix cycles for accepted-with-issues tasks only
2. Re-run all reviews (confidence check across all tasks)
3. Continue to next step
4. Stop
```

After the menu, recommend compaction before the next step: "This is a good point to compact context before the next step (`/compact`)."

### Batch Gate Red Flags — STOP

- Presenting "Fix remaining issues" option when all tasks passed clean
- Presenting the batch gate before every task is in (a), (b), or (c)
- Advancing to the next route step from inside the batch gate logic without an explicit user "continue"

## Terminal State

When the user chooses "continue" at the batch gate, compute the next skill to invoke as follows:

1. Find the index of `implement` in `config.md.route`.
2. Invoke `route[index+1]` (typically `integrate` in full pipeline; `test` in quick fix).

**Edge case — `implement` is the last entry.** If `implement` has no successor in the route, the route is malformed (every full-pipeline route should end with `test` after `integrate`; every quick-fix route should end with `test`). Refuse to advance and tell the user: "Cannot continue — `config.md` route ends at `implement`. Add `test` (and `integrate` if this is a full-pipeline route) and re-invoke."

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Mechanical tasks (1-2 files, clear spec) | Fast/cheap model (haiku) |
| Integration tasks (multi-file, pattern matching) | Standard model (sonnet) |
| Architecture/design/review | Most capable model (opus) |

## Task Tracking (TodoWrite)

Granular TodoWrite items covering the user-visible Process Steps. Numbering below is local TodoWrite enumeration; each item names the Process Step it covers. (Process Step 1 — read inputs and load Runtime Adjustments — is preliminary reading and does not get its own TodoWrite item.)

1. Ask phase config (covers Process Step 2).
2. Create feature branch / verify exists (covers Process Step 3).
3. Run baseline tests in throwaway worktree (covers Process Step 4).
4. [conditional — only if Auto-fix chosen on baseline failure] Dispatch task-00 in isolation (covers Process Step 5).
5. Dispatch tasks (covers Process Step 6). In full pipeline mode, create one TodoWrite task per wave (e.g., "Wave 1 / G1: T01, T02 — resolve bases, create worktrees, dispatch concurrently"). In quick fix mode, create one TodoWrite task per per-task-orchestrator dispatch (typically one task; possibly several if the batch includes fix tasks). Mark `in_progress` at dispatch; mark `completed` when every task in that wave (full) or that dispatch (quick) reaches a terminal state.
6. Present batch gate (covers Process Step 7).
7. Invoke next route step (covers Process Step 8).

Mark each task `in_progress` when starting, `completed` when done.

## Worked Example — Wave Execution (Full Pipeline)

Given the Worked Example in `parallelize/SKILL.md`:

**Pre-flight — baseline.** Implement creates `.worktrees/user-auth/baseline/` from the feature branch tip, runs baseline tests, deletes the worktree. Assume baseline passes (otherwise the Auto-fix path injects `task-00` and dispatches it in isolation before Wave 1).

**Wave 1.** Implement reads the Branch Map. Tasks 1 and 2 both have `Base = feature branch tip` and are file-disjoint. Resolve `feature branch tip` to the current tip of `qrspi/user-auth/main`, create worktrees `.worktrees/user-auth/task-01/` and `.worktrees/user-auth/task-02/` from that commit, dispatch both per-task orchestrator subagents concurrently, wait for both to return terminal status.

**Stage commit creation.** Both Wave 1 tasks now in terminal state. Implement sees Wave 2 needs `stage-after-G1`. Create branch `qrspi/user-auth/stage-after-G1` by merging task-01 and task-02 tips. (Composition is documented in `parallelization.md` § Stage Commits.)

**Wave 2.** Task 3's `Base = stage-after-G1` resolves to the freshly-created stage commit. Task 4's `Base = task-01 tip` resolves to the current tip of `qrspi/user-auth/task-01`. Create both worktrees, dispatch both per-task orchestrator subagents concurrently, wait for both terminal statuses.

**Batch gate.** All four tasks are now in terminal state. Present the batch gate; on "continue," invoke the next route step (Integrate).

## Worked Example — Quick Fix Single Task

Quick-fix run with one task at `tasks/task-01.md`:

**Pre-flight — baseline.** Implement creates `.worktrees/{slug}/baseline/` from the feature branch tip, runs baseline tests, deletes the worktree. Assume baseline passes.

**Single dispatch.** Create worktree `.worktrees/{slug}/task-01/` forked from the feature branch tip, dispatch the per-task orchestrator subagent for task-01, wait for terminal status.

**Batch gate.** Task is in terminal state. Present the batch gate; on "continue," invoke the next route step (Test).

## Red Flags — STOP

- Dispatching parallel tasks (full pipeline) that touch overlapping files (re-verify at runtime even if Parallelize cleared them).
- Skipping baseline tests because "they passed last time".
- Creating worktrees on main/master without a feature branch.
- Dispatching before the mode-appropriate input is approved (`parallelization.md` in full; `tasks/*.md` or `fixes/{type}-round-NN/*.md` per the quick-fix dispatch shape — see § Batch Gate Definition).
- Re-asking review depth/mode during fix-task dispatch (reuse from `config.md`).
- Proceeding after BLOCKED status from a per-task orchestrator subagent without changing approach.
- Dispatching a task whose dependencies haven't completed (or whose stage commit hasn't been created yet, full pipeline).
- Using a single TodoWrite task for all dispatches — create one task per wave (full) or per per-task-orchestrator dispatch (quick) so the user can track progress.
- Adding per-worktree `.claude/settings.json` files or per-worktree allow rules (the hook now governs subagent permissions; per-worktree settings are obsolete).
- Re-forking an existing task branch (re-runs reuse the existing branch and add commits — re-fork only at fresh worktree creation, replan-introduced tasks, or explicit user-requested reset).
- Advancing to the next route step before every task is in one of the three terminal states defined in "Batch Gate Definition (Release Conditions)".

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "These tasks are independent, skip the runtime overlap check" | `tasks/*.md` may have been edited after Parallelize approval. Re-verify before dispatch. |
| "Baseline tests failed but they're probably flaky" | Present to user. They decide, not you. |
| "Single task, skip the batch gate" | Single-task batches still get the batch gate (trivial but consistent — the gate is the only point where Implement hands control back). |
| "Quick fix has only one task — skip baseline" | Baseline failures masquerade as task failures; baseline runs in both modes. |
| "I can resolve `stage-after-G1` to a hash and write it back into `parallelization.md`" | The symbolic name is the contract; appending a hash drifts the artifact away from its approved form. Resolve in-memory. |
| "Just integrate this task now while the others run — it'll save time" | No. Integrate runs once per phase, after the batch gate releases. Per-task integration breaks the cross-task review's premise. |
| "I'll write `state.json` `current_step = integrate` myself when the batch is done" | Skills never write state directly. The hook layer does. If a transition is missing, file a hook bug; do not work around it in this skill. |

## Iron Rules — Final Reminder

```
NO TASK DISPATCH WITHOUT APPROVED INPUTS
```

**Re-fork prohibition.** Once a task branch exists, it is canonical. Re-runs reuse the branch and add commits. Re-fork only at fresh worktree creation, replan-introduced tasks, or explicit user-requested reset. **Why:** the model will helpfully "fix divergence" by re-forking, invalidating every downstream branch.

**Batch Gate release conditions.** Do not advance to the next route step until every task is in (a) clean, (b) accepted-with-issues, or (c) skipped-by-user. **Why:** without this gate, the model loops forever on partial-state tasks or rationalizes per-task integration that breaks the cross-task review's premise.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
