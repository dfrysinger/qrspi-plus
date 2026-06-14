
**Full pipeline:**
```
Goals → Questions → Research → Design → Phasing → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan (if needed)
```

> **Read the `Parallelize → Implement → Integrate` segment carefully.** Implement is *not* a per-task chain — it is the per-phase orchestrator step. Parallelize produces the parallelization plan and gets human approval; Implement then, for each task in the current phase, dispatches an implementer subagent (TDD) and on its DONE / DONE_WITH_CONCERNS terminal status dispatches the configured reviewer subagents in parallel against that task; main chat itself is the per-task orchestrator (flat dispatch — there is no per-task orchestrator subagent layer). When every task has cleared its review/fix cycles, Implement presents a batch gate and only then routes to Integrate. **Implement runs once per phase. Integrate runs once per phase.** Canonical batch-gate contract lives in `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop".

**Quick Fix pipeline** (skip Design/Phasing/Structure/Parallelize/Integrate):
```
Goals → Questions → Research → Plan → Implement → Test
```

> Quick fix has no Parallelize plan and no Integrate. Implement still owns per-task orchestration: for each task (typically one for the originally-requested fix; more if fix-task rounds occur) main chat dispatches an implementer subagent and reviewer subagents directly, then presents the **quick-fix batch gate** before routing to Test. See `implement/SKILL.md` § Quick Fix for the full batch-gate semantics in quick-fix mode.

| Step | # | What it does | Artifact |
|------|---|-------------|----------|
| **Goals** | 1 | Capture user intent, environmental constraints, per-goal problem framing (Problem / Why we care / What we know so far) | `goals.md` |
| **Questions** | 2 | Generate tagged research questions (no goal leakage) | `questions.md` |
| **Research** | 3 | Parallel specialist agents gather objective facts | `research/summary.md` |
| **Design** | 4 | Interactive design discussion: approach selection, key decisions, trade-offs, design-level test strategy, system diagram | `design.md` |
| **Phasing** | 5 | Author vertical slices and phase boundaries with replan gates; maintain `roadmap.md` and `future-*.md` | `phasing.md` |
| **Structure** | 6 | Map design to files, interfaces, component boundaries | `structure.md` |
| **Plan** | 7 | Detailed task specs with test expectations | `plan.md` + `tasks/*.md` |
| **Parallelize** | 8 | Analyze dependencies and file overlap; produce symbolic parallelization plan | `parallelization.md` |
| **Implement** | 9 | Resolve symbolic bases, create worktrees + stage commits, run baseline tests, dispatch implementer + reviewer subagents per task with TDD + tiered review loops, present batch gate | Working code |
| **Integrate** | 10 | Merge task branches, cross-task integration + security review, CI gate | Integration report |
| **Test** | 11 | Acceptance testing, PR creation, phase routing | Test results + PR (every phase) |
| **Replan** | — | Between phases — update remaining tasks based on learnings (out-of-route) | Updated `plan.md` + `tasks/*.md` |
