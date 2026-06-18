# Closing: Terminal state, model selection, task tracking, red flags

## Terminal State

**Compaction checkpoint: pre-handoff.** Implement batch complete; the next route step (typically Integrate in full pipeline; Test in quick fix) reads `parallelization.md` (or task specs) + every prior approved artifact + per-task reviewer findings on a fresh context. See using-qrspi `## Compaction Checkpoints`.

Surface a todo: title `Recommend /compact (pre-handoff) — implement`, description `pre-handoff: next route step reads parallelization.md + prior artifacts + per-task reviewer findings. User decides whether to /compact.`.

When the user chooses "continue" at the batch gate, find the index of `implement` in `config.md.route` and invoke `route[index+1]` (typically `integrate` in full pipeline; `test` in quick fix).

**Edge case — `implement` is the last entry.** Refuse to advance: "Cannot continue — `config.md` route ends at `implement`. Add `test` (and `integrate` if this is a full-pipeline route) and re-invoke."

## Model Selection Guidance

Task complexity maps to a routing **tier**, not a literal model name. The dispatcher resolves the tier to `(vendor, model)` via `config.md`'s `model_routing:` block (see § Tier Resolution Chain). For per-task tier-assignment rationale, see `skills/plan/SKILL.md` § Per-Task Classification.

| Task complexity | Recommended tier |
|-----------------|-------------------|
| Mechanical (1-2 files, clear spec) | `low` |
| Integration (multi-file, pattern matching) | `medium` |
| Architecture / design / review | `high` |

## Task Tracking (todo list)

Granular todo items for the user-visible Process Steps (Step 1 is preliminary reading, no item):

1. Ask phase config (Step 2). 2. Create / verify feature branch (Step 3). 3. Run baseline tests in throwaway worktree (Step 4). 4. [conditional] Dispatch task-00 in isolation when auto-fix chosen (Step 5). 5. Dispatch tasks (Step 6) — full pipeline: one todo per Wave; quick fix: one per per-task dispatch; mark `in_progress` at dispatch, `completed` when every task is terminal. 6. Present batch gate (Step 8) — OBC (Step 7) runs immediately before, no separate item (populated `## Dispatch defects` halts unconditionally). 7. Invoke next route step (Step 9).

Mark each task `in_progress` when starting, `completed` when done.

## Red Flags — STOP

- Dispatching parallel tasks (full pipeline) that touch overlapping files (re-verify at runtime).
- Skipping baseline tests because "they passed last time".
- Creating worktrees on main/master without a feature branch.
- Dispatching before the mode-appropriate input is approved.
- Re-asking review depth/mode during fix-task dispatch (reuse from `config.md`).
- Proceeding after BLOCKED status without changing approach.
- Dispatching a task whose dependencies haven't completed (stage commit missing, full pipeline).
- Re-forking an existing task branch (re-runs reuse the branch and add commits).
- Advancing to the next route step before every task is in one of the three terminal states.

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "Tasks are independent, skip the runtime overlap check" | `tasks/*.md` may have been edited after Parallelize approval. Re-verify. |
| "Baseline tests are probably flaky" | Present to user. They decide. |
| "Single task, skip the batch gate" | Single-task batches still get the batch gate. |
| "I can resolve `stage-after-W1` to a hash and write it back into `parallelization.md`" | Symbolic name is the contract; resolve in-memory. |
| "Just integrate this task now while others run" | No. Integrate runs once per phase, after the batch gate releases. |
| "Implementer self-review was clean — skip the reviewer dispatch" | No. Self-review does not substitute for the formal reviewer dispatch. |

## Iron Rules — Final Reminder

```
NO TASK DISPATCH WITHOUT APPROVED INPUTS
```

**Re-fork prohibition.** Once a task branch exists, it is canonical. Re-runs reuse it. **Batch Gate release conditions.** Do not advance until every task is in (a) clean, (b) accepted-with-issues, or (c) skipped-by-user. **Role separation.** Implementer and reviewer subagents are separate dispatches with fixed roles; reviewers never modify code; main chat never substitutes self-review for the formal reviewer dispatch.
