---
name: implement
description: Per-phase implementation orchestrator — resolves symbolic bases to concrete commits, creates worktrees and stage commits, runs baseline tests, dispatches per-task implementer subagents per the wave schedule, presents the batch gate, routes to the next route step (Integrate in full pipeline; Test in quick-fix).
---

# Implement (QRSPI Step 8)

**Announce at start:** "I'm using the QRSPI Implement skill to run the per-phase implementation loop."

> **Phase 1 of Dispatch→Implement rename.** This file's body still uses the prior "Dispatch" vocabulary throughout; Phase 2 rewrites the body. The skill is already invoked as `implement` — skill discovery uses the directory path (`skills/implement/SKILL.md`, per README → How Skills Work), so the directory move in this commit is the load-bearing change for invocation. See the rename commit history for context.

## Overview

Runtime owner of the `Parallelize → Dispatch → Implement(×N) → Integrate` segment. Reads the symbolic Branch Map from `parallelization.md`, resolves each `Base` to a concrete commit at runtime (creating stage commits on demand), creates worktrees, runs baseline tests, dispatches Implement once per task following the wave schedule, presents the batch gate when every task has reached a terminal state, and only then invokes the next route step (typically Integrate).

## Iron Law

```
NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN
```

If `parallelization.md` is missing or its frontmatter is not `status: approved`, refuse to run.

## Dispatch Is the Per-Phase Implement Loop

```
DISPATCH FIRES IMPLEMENT N TIMES PER PHASE,
THEN ROUTES TO INTEGRATE EXACTLY ONCE.
```

### Batch Gate Definition (Release Conditions)

The batch gate is the human gate Dispatch presents after every task in `parallelization.md` has reached one of the following terminal states:

- (a) **Clean** — completed Implement with no unresolved reviewer findings
- (b) **Accepted-with-issues** — completed Implement with reviewer findings that the user explicitly accepted (logged but not blocking)
- (c) **Skipped-by-user** — explicitly skipped at the user's request before or during dispatch

All N tasks must be in (a), (b), or (c) before the batch gate fires. The batch gate is the only point at which Dispatch relinquishes control. The user's decision at the batch gate (continue / re-run reviews / fix issues / stop) is what releases the loop and routes to Integrate.

**Why:** without the (a)/(b)/(c) gate, the model rationalizes "this one task is done, just integrate it" and per-task integration breaks the cross-task review's premise. Dispatch does not advance to Integrate task-by-task.

### State Transition Contract

Skills do not write `state.json` directly — the hook layer owns it. See `using-qrspi/SKILL.md` § Hook-Managed State.

Behavior contract Dispatch relies on:

- While Dispatch is mid-batch: `state.json` `current_step` stays at `implement` (or `dispatch`, depending on hook implementation); `active_task` reflects the currently dispatched task.
- After the batch gate releases and Dispatch invokes the next route step: `current_step` advances to `integrate` (or whichever step is next in `config.md` route).

Readers verifying `current_step` mid-batch should cross-check `active_task` against `parallelization.md` to know whether the batch is still in flight, regardless of what the step name reads. If a hook does not yet realize a transition asserted above, file a hook bug; do not work around it by writing state directly.

## Artifact Gating

Required inputs:

- `parallelization.md` with `status: approved`
- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md` (for fix-task routing)
- `design.md` with `status: approved` (phase definitions)
- `config.md`

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Same procedure as Parallelize. See `using-qrspi/SKILL.md` § Config Validation Procedure.

<HARD-GATE>
Do NOT dispatch implementation subagents without an approved `parallelization.md`.
Do NOT dispatch parallel tasks that touch overlapping files (re-verify against the Branch Map at runtime — `tasks/*.md` may have been edited after Parallelize approval).
Do NOT create worktrees on main/master without a feature branch.
Do NOT advance to the next route step until every task is in one of the three terminal states (clean / accepted-with-issues / skipped-by-user) defined in "Batch Gate Definition (Release Conditions)" above.
</HARD-GATE>

## Phase-Level Configuration (Runtime)

`review_depth` and `review_mode` are runtime concerns owned by Dispatch. At the start of each Dispatch run (per phase), ask the user:

1. **Review depth:** "Quick (4 correctness reviewers) or Deep (correctness + thoroughness, all 8 reviewers)?"
2. **Review mode:** "Single round or Loop until clean?"

Write choices to `config.md` as `review_depth` and `review_mode`. Fix-task dispatches reuse the same settings — do not re-ask. In quick fix mode (no Dispatch), Implement asks and writes these same fields. Source of truth is always `config.md`.

## Branch Model — Runtime Resolution

Dispatch consumes the symbolic Branch Map from `parallelization.md` (see `parallelize/SKILL.md` § Branch Model). At runtime, Dispatch resolves each `Base` value as follows:

| Symbolic base | Runtime resolution |
|---------------|--------------------|
| `feature branch tip` | The current tip of `qrspi/{slug}` |
| `task-NN tip` | The current tip of `qrspi/{slug}/task-NN` (must already exist before forking — enforce wave ordering) |
| `stage-after-G{N}` | A new branch `qrspi/{slug}/stage-after-G{N}` created by merging the tips of every task in Group N (composition listed in `parallelization.md` § Stage Commits). Create on demand, before forking any task whose `Base` names it. |
| `task-00 tip` | The current tip of `qrspi/{slug}/task-00` (only valid after baseline-fix injection — see "Baseline Tests" below) |

**Stage commit creation order:** walk the Branch Map in dispatch-wave order. Before starting a wave, verify every `stage-after-G{N}` referenced by any task in that wave exists; if not, create it from the named composition. Stage branches are scratch infrastructure — Integrate deletes them after merging the leaves (see `integrate/SKILL.md` § Merge Strategy).

**Re-fork prohibition.** Once a task branch exists, it is canonical. Implementer-fix-round dispatches reuse the existing branch and add commits. Do not silently re-fork.

**Why:** downstream branches that descend from a re-forked task branch would be invalidated, and the model will helpfully "fix divergence" by re-forking unless explicitly stopped. Re-forks happen only at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset.

## Subagent Permissions

Before dispatching any implementation subagent, write `.claude/settings.json` into each *task* worktree directory (`.worktrees/{slug}/task-NN/`). The throwaway baseline worktree at `.worktrees/{slug}/baseline/` does not need a settings file — Dispatch runs baseline tests directly there, not via a subagent.

**Why:** approval prompts inside subagents block execution silently — the subagent stalls without surfacing the prompt. Pre-writing broad permissions eliminates this failure mode. Worktrees are isolated branches, so broad tool permissions here do not affect the main project.

**Settings file content** (write to `{worktree}/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [
      "Edit(**)",
      "Write(**)",
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(pytest *)",
      "Bash(python3 *)",
      "Bash(cargo *)",
      "Bash(go *)",
      "Bash(make *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(rm *)",
      "Bash(chmod *)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(grep *)",
      "Bash(sed *)",
      "Bash(awk *)",
      "Bash(echo *)",
      "Bash(touch *)",
      "Bash(wc *)",
      "Bash(sort *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(diff *)"
    ],
    "deny": []
  }
}
```

### Fallback Approach

If worktree-level `.claude/settings.json` is not loaded by the subagent (Claude Code only loads settings from the project root or `~/.claude/`), fall back to the main project settings:

1. Open `.claude/settings.json` in the main project root.
2. For each *task* worktree path, append path-scoped allow rules in the `"allow"` array using the pattern `"Bash(* {worktree_path}/*)"` or equivalent glob. (Skip `.worktrees/{slug}/baseline/` — Dispatch runs baseline tests directly there, not via a subagent.)
3. After the subagent completes, remove those path-scoped entries.

**Never leave temporary permission entries in the main project `.claude/settings.json` after subagents complete.**

## Process Steps

The order matters: baseline tests run **before** per-task worktree creation so that a baseline failure can inject `task-00` without violating the re-fork prohibition. If worktrees were created first, dependent task branches would already be forked from the wrong base.

1. Read `parallelization.md` (Branch Map + Stage Commits + Execution Order narrative; if a `## Runtime Adjustments` section exists from a prior session, load its overrides into the in-memory base-resolution table).
2. Ask phase config (`review_depth`, `review_mode`), write to `config.md` (skip on fix-task dispatches — reuse existing values).
3. Create feature branch `qrspi/{slug}` from the current branch if it does not exist (first phase only).
4. **Run baseline tests** in a single throwaway worktree at `.worktrees/{slug}/baseline/` forked from the feature branch tip. **Resume precondition:** if `.worktrees/{slug}/baseline/` already exists when this step starts, delete it first — the prior baseline result is not trusted across sessions because the feature branch tip may have advanced. (One check is sufficient: every Group 1 task forks from this same commit, so per-task baselines would be identical; downstream-group bases derive from task work that hasn't happened yet and is validated by Implement's reviewers.) See "Baseline Tests" below for the 3 options when failures occur. **Invariant:** if the pipeline continues past this step, the baseline worktree must be gone before any per-task worktree exists.
5. **If baseline failed and the user chose Auto-fix:** dispatch `task-00` first, in isolation:
    - Delete `.worktrees/{slug}/baseline/` (per Step 4's invariant).
    - Write the `task-00` Branch Map row and the `## Runtime Adjustments` section to `parallelization.md` (see "Baseline Tests" Auto-fix path).
    - Create only the `task-00` worktree at `.worktrees/{slug}/task-00/`, forked from feature branch tip.
    - Write `.claude/settings.json` into `.worktrees/{slug}/task-00/` (see "Subagent Permissions"). If this is the first task worktree of the session, also decide between the worktree-level approach and the fallback approach (see "Subagent Permissions / Fallback Approach"); the decision applies to every later worktree this session.
    - Dispatch `task-00` through Implement, wait for terminal state.
    - Once `task-00` is in terminal state, proceed to Step 6 with the in-memory resolution table now overlaying Runtime Adjustments (so dependents resolve to `task-00 tip`).
6. **For each wave** in the Execution Order, in order:
    - Resolve every task's effective base: read the Branch Map's `Base` column, then apply `## Runtime Adjustments` overrides on top.
    - Create any required `stage-after-G{N}` branch (merging the named Group's leaves).
    - Create the per-task worktree at `.worktrees/{slug}/task-NN/`. Verify `.worktrees/` is in `.gitignore`.

      **Resume precondition.** Before attempting `git worktree add`, if any leftover state exists for `task-NN` (worktree dir or branch already present), see `references/resume-preconditions.md` for the four-case classification table and the inspect-and-decide procedure. The leftover-state handling differs from the baseline worktree's silent-delete rule because the baseline worktree contains no user work, while task branches and worktrees can.
    - Write `.claude/settings.json` into the new task worktree (see "Subagent Permissions"). Use the fallback-approach choice made on the first worktree of the session (or make it now if this is the first worktree).
    - Fire the wave's tasks concurrently (one Implement subagent per task; multiple Agent tool calls in parallel, each with `isolation: worktree`).
    - Wait for every task in the wave to reach a terminal status.
    - If the next wave needs a `stage-after-G{N}` stage commit composed from this wave's leaves, create it now.
7. When every task in the phase has reached a terminal state, present the batch gate (see "Batch Gate" below).
8. On user "continue", invoke the next route step (see "Terminal State" for the routing algorithm).

## Baseline Tests

Run baseline tests in a single throwaway worktree at `.worktrees/{slug}/baseline/` (forked from the feature branch tip). If `.worktrees/{slug}/baseline/` already exists from a prior halted run, delete it first; the prior result is not trusted across sessions because the feature branch tip may have changed.

If tests fail, present failure summary with 3 options:

- **(a) Auto-fix (recommended):** Inject baseline fix task `task-00` with all others depending on it. `task-00` uses `task: 0` in frontmatter and `pipeline: full`. Update `parallelization.md`:
  - Append one row to the Branch Map: `task-00 → qrspi/{slug}/task-00 (base: feature branch tip)` (without rewriting existing rows — they remain the approved record of the original plan).
  - Append a new `## Runtime Adjustments` section listing every task whose effective base changed because of the injection: `task-NN: new base = task-00 tip` (or `task-NN: new base = stage-after-G{N} re-merged on top of task-00 tip`, when the original base was a stage commit). This section is informational and does not change `status: approved` — it is the persistent record of Dispatch's runtime base-resolution decisions, so a fresh agent reading `parallelization.md` after a session restart can rebuild the resolution table without guessing.
  - On every subsequent dispatch in this run, Dispatch resolves bases by reading the Branch Map first, then applying `## Runtime Adjustments` overrides on top.
  Dispatched through Implement like any other task.

  **Repeated baseline failures (rare).** If a second baseline failure occurs in the same phase, inject `task-00b` (then `task-00c`, etc.). Append the new task as a fresh Branch Map row (`task-00b → qrspi/{slug}/task-00b (base: task-00 tip)`); under `## Runtime Adjustments`, append new override lines but do *not* duplicate the section heading. Original `task-00` row and original Runtime Adjustments lines stay intact.
- **(b) Proceed anyway:** Log failures to `reviews/baseline-failures.md`.
- **(c) Stop:** Halt the pipeline.

**Invariant — baseline worktree gone before any per-task worktree exists.** Per-option behavior:

- **(a) Auto-fix:** delete `.worktrees/{slug}/baseline/` as the first sub-step of Process Step 5, before creating the `task-00` worktree.
- **(b) Proceed anyway:** delete `.worktrees/{slug}/baseline/` immediately after writing `reviews/baseline-failures.md`, before entering the wave loop.
- **(c) Stop:** no deletion required — the pipeline halts. The user can clean up `.worktrees/{slug}/baseline/` manually if they want.

## Wave Dispatch

Dispatch tasks in the wave order Parallelize specified. For each wave:

1. Verify every task in the wave has its `Base` resolved (and any required stage commit created).
2. Mark each task `in_progress` in TodoWrite.
3. Fire all tasks in the wave concurrently (one Implement subagent per task; multiple Agent tool calls in parallel, each with `isolation: worktree`).
4. Wait for every task in the wave to return a terminal status (DONE, DONE_WITH_CONCERNS, or unresolved-after-3-fix-cycles per `implement/SKILL.md` § Review Fix Loop).
5. Mark each wave's tasks `completed` in TodoWrite.
6. If the next wave depends on a stage commit (`stage-after-G{N}`), create it now from the just-completed group's tips.
7. Move to the next wave.

## Fix Task Routing

When handling fix tasks from integration, CI, or test failures, see `references/fix-task-routing.md`.

## Batch Gate (After All Tasks)

When every current-phase task has reached one of the terminal states defined in "Batch Gate Definition (Release Conditions)" above — **(a) clean**, **(b) accepted-with-issues**, or **(c) skipped-by-user** — present summary:

- Which tasks passed clean (state a)
- Which tasks have unresolved issues that the user accepted (state b — issue summaries + acceptance reasons)
- Which tasks were skipped (state c — skip reason)
- Review round history per task

User chooses:

1. **Fix remaining issues and re-run reviews** — re-enter fix cycles for accepted-with-issues tasks only.
2. **Re-run all reviews** — confidence check across all tasks.
3. **Continue to next step**.
4. **Stop**.

In full pipeline mode, this batch gate lives in Dispatch. In quick fix mode, it lives in Implement.

## Terminal State

Recommend compaction: "Dispatch complete. This is a good point to compact context before the next step (`/compact`)."

When the user chooses "continue" at the batch gate, compute the next skill to invoke as follows:

1. Find the index of `implement` in `config.md.route`.
2. Invoke `route[index+1]` (typically `integrate`).

Do NOT use `dispatch`'s own index in the route — `route[dispatch_index+1]` is `implement`, which would loop back into the Implement dispatch. The `implement` entry is the route's placeholder for the loop; the entry that follows it is what comes after the loop.

**Edge case — `implement` is the last entry.** If `implement` has no successor in the route, the route is malformed (every full-pipeline route should end with `test`). Refuse to advance and tell the user: "Cannot continue — `config.md` route ends at `implement`, which is the loop placeholder. Add `integrate`, `test`, or another successor and re-invoke."

For quick-fix pipeline (no Dispatch in route), Plan invokes Implement directly — Implement asks review depth/mode and presents its own batch gate.

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Mechanical tasks (1-2 files, clear spec) | Fast/cheap model (haiku) |
| Integration tasks (multi-file, pattern matching) | Standard model (sonnet) |
| Architecture/design/review | Most capable model (opus) |

## Task Tracking (TodoWrite)

Granular TodoWrite items covering the user-visible Process Steps. Numbering below is local TodoWrite enumeration; each item names the Process Step it covers. (Process Step 1 — read `parallelization.md` and load Runtime Adjustments — is preliminary reading and does not get its own TodoWrite item.)

1. Ask phase config (covers Process Step 2).
2. Create feature branch / verify exists (covers Process Step 3).
3. Run baseline tests in throwaway worktree (covers Process Step 4).
4. [conditional — only if Auto-fix chosen on baseline failure] Dispatch task-00 in isolation, including writing `.claude/settings.json` into the task-00 worktree (covers Process Step 5).
5. For each wave in the Execution Order, create a separate TodoWrite task (e.g., "Wave 1 / G1: T01, T02 — resolve bases, create worktrees, dispatch concurrently") covering Process Step 6. Mark `in_progress` at dispatch; mark `completed` when every task in that wave reaches a terminal state. Writing `.claude/settings.json` into each new task worktree happens during Step 6; the fallback-approach decision is made on the first worktree of the session if Step 5 was skipped.
6. Present batch gate (covers Process Step 7).
7. Invoke next route step (covers Process Step 8).

Mark each task `in_progress` when starting, `completed` when done.

## Worked Example — Wave Execution

Given the Worked Example in `parallelize/SKILL.md`:

**Pre-flight — baseline.** Dispatch creates `.worktrees/user-auth/baseline/` from the feature branch tip, runs baseline tests, deletes the worktree. Assume baseline passes (otherwise the Auto-fix path injects `task-00` and dispatches it in isolation before Wave 1).

**Wave 1.** Dispatch reads the Branch Map. Tasks 1 and 2 both have `Base = feature branch tip` and are file-disjoint. Resolve `feature branch tip` to the current tip of `qrspi/user-auth`, create worktrees `.worktrees/user-auth/task-01/` and `.worktrees/user-auth/task-02/` from that commit, write `.claude/settings.json` into each (this is the first worktree of the session, so also decide between worktree-level and fallback approach — see "Subagent Permissions"), dispatch both Implement subagents concurrently, wait for both to return terminal status.

**Stage commit creation.** Both Wave 1 tasks now in terminal state. Dispatch sees Wave 2 needs `stage-after-G1`. Create branch `qrspi/user-auth/stage-after-G1` by merging task-01 and task-02 tips. (Composition is documented in `parallelization.md` § Stage Commits.)

**Wave 2.** Task 3's `Base = stage-after-G1` resolves to the freshly-created stage commit. Task 4's `Base = task-01 tip` resolves to the current tip of `qrspi/user-auth/task-01`. Create both worktrees, write `.claude/settings.json` into each (the fallback-approach decision was made in Wave 1), dispatch both Implement subagents concurrently, wait for both terminal statuses.

**Batch gate.** All four tasks are now in terminal state. Present the batch gate; on "continue," invoke the next route step (Integrate).

## Red Flags — STOP

- Dispatching parallel tasks that touch overlapping files (re-verify at runtime even if Parallelize cleared them).
- Skipping baseline tests because "they passed last time".
- Creating worktrees on main/master without a feature branch.
- Dispatching before `parallelization.md` is approved.
- Re-asking review depth/mode during fix-task dispatch (reuse from `config.md`).
- Proceeding after BLOCKED status from Implement without changing approach.
- Dispatching a task whose dependencies haven't completed (or whose stage commit hasn't been created yet).
- Using a single TodoWrite task for all Implement dispatches — create one task per wave so the user can track progress.
- Dispatching implementation subagents without first writing `.claude/settings.json` to each worktree directory.
- Leaving temporary permission entries in main project `.claude/settings.json` after subagents complete.
- Re-forking an existing task branch (re-runs reuse the existing branch and add commits — re-fork only at fresh worktree creation, replan-introduced tasks, or explicit user-requested reset).
- Advancing to Integrate before every task is in one of the three terminal states defined in "Batch Gate Definition (Release Conditions)".

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "These tasks are independent, skip the runtime overlap check" | `tasks/*.md` may have been edited after Parallelize approval. Re-verify before dispatch. |
| "Baseline tests failed but they're probably flaky" | Present to user. They decide, not you. |
| "Single task, skip the batch gate" | Single-task phases still get the batch gate (trivial but consistent — the gate is the only point where Dispatch hands control back). |
| "I can resolve `stage-after-G1` to a hash and write it back into `parallelization.md`" | The symbolic name is the contract; appending a hash drifts the artifact away from its approved form. Resolve in-memory. |
| "Just integrate this task now while the others run — it'll save time" | No. Integrate runs once per phase, after the batch gate releases. Per-task integration breaks the cross-task review's premise. |
| "I'll write `state.json` `current_step = integrate` myself when the batch is done" | Skills never write state directly. The hook layer does. If a transition is missing, file a hook bug; do not work around it in this skill. |

## Iron Rules — Final Reminder

```
NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN
```

**Re-fork prohibition.** Once a task branch exists, it is canonical. Re-runs reuse the branch and add commits. Re-fork only at fresh worktree creation, replan-introduced tasks, or explicit user-requested reset. **Why:** the model will helpfully "fix divergence" by re-forking, invalidating every downstream branch.

**Batch Gate release conditions.** Do not advance to Integrate until every task is in (a) clean, (b) accepted-with-issues, or (c) skipped-by-user. **Why:** without this gate, the model loops forever on partial-state tasks or rationalizes per-task integration that breaks the cross-task review's premise.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
