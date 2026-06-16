
Pipeline state is derived from artifact frontmatter (`status: approved`). No pipeline-state cache file gates step ordering. To determine the current step, walk `config.md.route` and find the first entry whose artifact does not have `status: approved`.

Pipeline ordering is enforced by the `<HARD-GATE>` blocks in each skill — every skill checks predecessor approval at its top and refuses to run if missing. Subagent containment is the runtime sandbox's responsibility (auto-mode plus Claude's judgment); there is no in-pipeline worktree wall.

The single piece of derived state worth persisting is `phase_start_commit`, which Replan and Test use to scope post-phase diffs. It lives in `plan.md` frontmatter, written when `plan.md` is approved. See `plan/SKILL.md` → "`phase_start_commit` capture at approval time" for the exact mechanic and the git-log fallback for non-git or unpopulated runs.

**The Implement batch trap to avoid:** "one task done" does NOT mean "advance to integrate." Implement runs once per phase and fires per-task subagents in a wave; the batch is only done when every task in `parallelization.md` has cleared its review/fix cycles. Verify against `parallelization.md` before routing forward.

### Orchestration Boundary applies to every phase

During Implement, Integrate, and Test, the pipeline enforces an **orchestration boundary**: only subagent commits whose `git log --format='%an'` matches `qrspi-<agent>` may land in the integration branch. Main-chat commits and any commit without the `qrspi-` author prefix are boundary violations.

The per-phase SKILL bodies carry the full HARD-RULE, the observability-check step, and the batch-gate menu additions:
- **Implement:** `skills/implement/SKILL.md` § Step N — Orchestration boundary observability check
- **Integrate:** `skills/integrate/SKILL.md` § Orchestration Boundary
- **Test:** `skills/test/SKILL.md` § Orchestration Boundary

The primitive is `scripts/orchestration-boundary-check.sh --phase <directory-name>`, which writes `reviews/<phase>/orchestration-boundary.md`. The script always exits 0 (fail-soft); a non-empty report is the signal at the batch gate. To revert confirmed violations, use the implementer-protocol `revert-orchestration-drift` fix-task mode.
