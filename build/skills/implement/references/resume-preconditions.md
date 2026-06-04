# Resume Preconditions — Leftover Task Worktree State

Read this file only when, during Process Step 6, you find leftover state for `task-NN` (the worktree dir at `.worktrees/{slug}/task-NN/` exists, or the branch `qrspi/{slug}/task-NN` exists, before Implement has tried to create either in this run).

## Case Classification

Before running `git worktree add` for `task-NN`, classify leftover state into one of four cases:

| Case | Worktree dir exists? | Branch exists? | Action |
|---|---|---|---|
| 1 | no | no | Normal fresh fork — proceed with `git worktree add .worktrees/{slug}/task-NN/ -b qrspi/{slug}/task-NN <resolved-base>`. |
| 2 | yes | yes | Run "Inspect-and-decide" below. |
| 3 | no | yes | Run `git worktree add .worktrees/{slug}/task-NN/ qrspi/{slug}/task-NN` to attach a worktree to the existing branch (no re-fork). Then run divergence check from "Inspect-and-decide". If diverged, present the option set; if not diverged, proceed normally. |
| 4 | yes | no | Pathological state (worktree dir present without backing branch — likely a manual deletion). Stop and present to the user with the worktree path; do not attempt automatic recovery. |

## Inspect-and-decide Procedure

Applies to Cases 2 and 3-divergent.

1. Resolve the task's expected base per the algorithm at the top of Process Step 6 in `implement/SKILL.md` (call this `expected_base`, a commit SHA).

2. Compute the current common ancestor: `common_ancestor = git merge-base qrspi/{slug}/task-NN <expected_base>`. The branch is **in-sync** if `common_ancestor == expected_base`; **diverged** otherwise.

   This check is correct for simple linear histories (the common branch-from-feature-tip case). Caveat: `git merge-base` returns the best common ancestor, *not* necessarily the original fork point. If the task branch has merged from, rebased onto, or cherry-picked the feature branch since being forked, the common ancestor may be a later commit than the original fork — in that case the in-sync check still says "in-sync" (the ancestor relationship still holds), and the Reuse path stays correct. The pathological case is when a task branch was rewritten such that it no longer descends from any commit reachable from `expected_base` (e.g., force-pushed to a parallel history): `git merge-base` returns nothing, divergence is reported, and the user can decide via the option set.

   Do NOT use `git log -1 --format=%H` here — that returns the tip, not the ancestor, and would falsely flag any branch with task commits as diverged.

3. Capture the branch's tip (`git rev-parse qrspi/{slug}/task-NN`) and the worktree's working-tree status (`git -C .worktrees/{slug}/task-NN/ status --porcelain` if the dir exists).

4. Present the user with the inspection summary (expected base, actual fork, tip, working-tree status) and three options:

   - **Reuse**: keep the existing branch and worktree as the Implement starting point. Valid when the user confirms the divergence (if any) and the working-tree state are intentional. No re-fork; Implement attaches the per-task subagent to the existing worktree as-is. *In Case 3, "Reuse" specifically means proceeding from the diverged branch tip and accepting that downstream tasks may need to re-resolve their bases.*

   - **Reset** (the carve-out the Re-fork prohibition's "explicit user-requested reset" clause refers to): in Case 2 destroys both committed task work and uncommitted working-tree changes; in Case 3 destroys only committed task work (no worktree existed before this step). Implement surfaces the case-appropriate consequence, requires a second explicit confirm, then in **both cases** first runs `git worktree remove .worktrees/{slug}/task-NN/` (in Case 2 this removes the leftover worktree; in Case 3 it removes the worktree just attached for inspection — `git branch -D` would otherwise refuse to delete a checked-out branch), then runs `git branch -D qrspi/{slug}/task-NN` and re-forks from `expected_base`.

   - **Stop**: halt the pipeline so the user can investigate manually.
