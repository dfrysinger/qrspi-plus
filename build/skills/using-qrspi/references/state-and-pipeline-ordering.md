
Pipeline state is derived from artifact frontmatter (`status: approved`). No pipeline-state cache file gates step ordering. To determine the current step, walk `config.md.route` and find the first entry whose artifact does not have `status: approved`.

Pipeline ordering is enforced by the `<HARD-GATE>` blocks in each skill — every skill checks predecessor approval at its top and refuses to run if missing. Subagent containment is the runtime sandbox's responsibility (auto-mode plus Claude's judgment); there is no in-pipeline worktree wall.

The single piece of derived state worth persisting is `phase_start_commit`, which Replan and Test use to scope post-phase diffs. It lives in `plan.md` frontmatter, written when `plan.md` is approved. See `plan/SKILL.md` → "`phase_start_commit` capture at approval time" for the exact mechanic and the git-log fallback for non-git or unpopulated runs.

**The Implement batch trap to avoid:** "one task done" does NOT mean "advance to integrate." Implement runs once per phase and fires per-task subagents in a wave; the batch is only done when every task in `parallelization.md` has cleared its review/fix cycles. Verify against `parallelization.md` before routing forward.
