# Branch Model — Runtime Resolution (Full Pipeline)

In full pipeline mode, Implement consumes the symbolic Branch Map from `parallelization.md` (see `parallelize/SKILL.md` § Branch Model). At runtime, Implement resolves each `Base` as follows:

| Symbolic base | Runtime resolution |
|---------------|--------------------|
| `feature branch tip` | The current tip of `qrspi/{slug}/main` |
| `task-NN tip` | The current tip of `qrspi/{slug}/task-NN` (must already exist before forking — enforce wave ordering) |
| `stage-after-W{N}` | A new branch `qrspi/{slug}/stage-after-W{N}` created by merging the tips of every task in Wave N (composition listed in `parallelization.md` § Stage Commits). Create on demand. |
| `task-00 tip` | The current tip of `qrspi/{slug}/task-00` (only valid after baseline-fix injection) |

Walk the Branch Map in Wave-dispatch order. Before starting a Wave, verify every `stage-after-W{N}` referenced by any task in that Wave exists; if not, create it from the named composition. Stage branches are scratch infrastructure — Integrate deletes them after merging the leaves.

**Re-fork prohibition.** Once a task branch exists, it is canonical. Fix-round dispatches reuse the existing branch and add commits. Do not silently re-fork. **Why:** downstream branches that descend from a re-forked task branch would be invalidated, and the model will helpfully "fix divergence" by re-forking unless explicitly stopped. Re-forks happen only at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset.

In quick fix mode, there is no Branch Map. Each task forks directly from the feature branch tip into its own worktree. The re-fork prohibition still applies.
