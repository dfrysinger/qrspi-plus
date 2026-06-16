The four invariants that, when violated, produce the most damage:

1. **Each step requires its declared inputs approved.** Artifact gating is not advisory — skills refuse to run without approved prerequisites. Do not "skip ahead." Use mid-pipeline entry only with the existing-artifacts contract.

2. **`status: approved` in YAML frontmatter is the only approval marker.** Pipeline progression is derived from frontmatter — no state cache file gates ordering. The single piece of derived state worth persisting (`phase_start_commit`) lives in `plan.md` frontmatter; see `plan/SKILL.md`.

3. **Backward loops cascade forward — never patch one artifact in isolation.** New learnings at step N require updating the earliest affected artifact, re-reviewing it, and re-approving every step from there to N. Drift between artifacts breaks every downstream contract.

4. **The `Implement → Integrate` segment is per-phase, not per-task.** Implement runs once per phase; main chat itself is the per-task orchestrator, firing implementer + reviewer subagents per task in the wave (flat dispatch — no per-task orchestrator subagent). Integrate runs once per phase. "One task done" does NOT mean "advance to integrate" — verify against `parallelization.md` (every task in the phase) before routing forward. See `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop" for the canonical contract.
