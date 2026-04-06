---
name: worktree
description: Use when plan.md is approved and the QRSPI pipeline needs task dispatch — analyzes dependencies, selects execution mode, creates worktrees, dispatches to Implement
---

# Worktree (QRSPI Step 7)

**Announce at start:** "I'm using the QRSPI Worktree skill to analyze task dependencies and dispatch implementation."

## Overview

Analyze task dependencies for the current phase, determine execution mode (sequential/parallel/hybrid), create worktrees, dispatch tasks to Implement. Orchestrator in main conversation.

## Iron Law

```
NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN
```

## Artifact Gating

Read `config.md` to determine pipeline mode. Required inputs:

- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md` (for fix task routing)
- `design.md` with `status: approved` (phase definitions)
- `config.md`

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

<HARD-GATE>
Do NOT dispatch implementation subagents without an approved parallelization plan.
Do NOT dispatch parallel tasks that touch overlapping files.
Do NOT create worktrees on main/master without a feature branch.
This applies regardless of how simple the task appears.
</HARD-GATE>

## Phase-Level Configuration

At the start of each Worktree dispatch, ask the user two questions:

1. **Review depth:** "Quick (4 correctness reviewers) or Deep (correctness + thoroughness, all 8 reviewers)?"
2. **Review mode:** "Single round or Loop until clean?"

Write choices to `config.md` as `review_depth` and `review_mode` fields. Fix-task dispatches reuse same settings — do not re-ask. In quick fix mode (no Worktree), Implement asks and writes these same fields. Source of truth is always `config.md`.

## Execution Modes

| Mode | When | How |
|------|------|-----|
| Sequential | Tasks have chain dependencies (A->B->C) | One subagent at a time, each in its own worktree |
| Parallel | Tasks are independent, touch different files | Multiple Agent tool calls with `isolation: worktree`, fired simultaneously |
| Hybrid | Mix of independent and dependent tasks | Parallel groups dispatched together, sequential between groups |

## Process

```mermaid
flowchart TD
    A[Verify plan.md approved, read config.md] --> B[Identify current phase tasks]
    B --> C[Analyze dependencies]
    C --> D[Determine execution mode]
    D --> E[Present parallelization plan]
    E --> F{User approves plan?}
    F -->|no| G[Revise plan]
    G --> E
    F -->|yes| H[Create worktrees - .worktrees/ in .gitignore]
    H --> I[Run baseline tests per worktree]
    I --> J{Baseline passes?}
    J -->|no| K[Present failures to user - 3 options]
    K -->|Auto-fix| N[Inject baseline fix task-00, all others depend on it]
    N --> L
    K -->|Proceed anyway| O[Log to reviews/baseline-failures.md]
    O --> L
    K -->|Stop| M[Pipeline halted]
    J -->|yes| L((Dispatch tasks to Implement))
```

## Branch Model

1. **Feature branch:** Created from the current branch (typically `main`) at the start of the first phase: `qrspi/{slug}` (e.g., `qrspi/user-auth`). For subsequent phases, the feature branch already exists.
2. **Task branches:** Each worktree forks from the feature branch: `qrspi/{slug}/task-NN` (e.g., `qrspi/user-auth/task-01`).
3. **Merge target:** Integrate merges task branches into the feature branch.
4. **PR target:** Test creates the PR from the feature branch to the base branch.

## Process Steps

1. Create feature branch if it doesn't exist (first phase only)
2. Identify current phase's tasks from `plan.md` phase definitions
3. Analyze dependencies between tasks for parallelization opportunities
4. Determine execution mode (sequential/parallel/hybrid)
5. Present parallelization plan to user for approval
6. Create worktrees from the feature branch (verify `.worktrees/` in `.gitignore`)
7. Run baseline tests in each worktree. If tests fail, present failure summary with 3 options:
   - **(a) Auto-fix (recommended):** Inject baseline fix task (`task-00`) with all others depending on it. `task-00` uses `task: 0` in frontmatter. Dispatched through Implement like any other task.
   - **(b) Proceed anyway:** Log failures to `reviews/baseline-failures.md`.
   - **(c) Stop:** Halt the pipeline.
8. Dispatch tasks to Implement skill

## Fix Task Routing

When handling fix tasks from integration, CI, or test failures, read from `fixes/{type}-round-NN/*.md` instead of `tasks/*.md`. Fix task files follow the same format as regular task files. For fix-task dispatches, append new branch entries to `parallelization.md` (informational additions, not structural changes requiring re-approval).

## Artifact

`parallelization.md` — which tasks run parallel, which sequential, worktree assignments, rationale. Written with `status: draft` in YAML frontmatter. Includes branch map (e.g., `task-01 -> qrspi/{slug}/task-01`). Review depth/mode stored in `config.md`, not here.

## Human Gate

Present parallelization plan as a Mermaid dependency graph. Example:

```mermaid
flowchart LR
    subgraph parallel1["Parallel Group 1"]
        T1[Task 1: Auth + profiles\nworktree: task-01]
        T2[Task 2: Box CRUD\nworktree: task-02]
    end
    subgraph sequential["Sequential"]
        T3[Task 3: Invitations\nworktree: task-03]
    end
    T1 --> T3
    T2 --> T3
```

Below the graph, include branch map and execution mode summary. On approval, write `status: approved` in frontmatter and commit.

## Batch Gate (After All Tasks)

When all current-phase tasks complete, present summary:

- Which tasks passed clean
- Which tasks have unresolved issues (with issue summaries)
- Review round history per task

User chooses:

1. **Fix remaining issues and re-run reviews** — re-enter fix cycles for unresolved tasks only
2. **Re-run all reviews** — confidence check across all tasks
3. **Continue to next step**
4. **Stop**

In full pipeline mode, this batch gate lives in Worktree. In quick fix mode, it lives in Implement.

## Terminal State

Recommend compaction: "Parallelization plan approved. This is a good point to compact context before dispatch (`/compact`)."

Dispatch tasks to Implement skill. After all tasks return, present the batch gate. When the user chooses to continue, invoke the next skill in the `config.md` route after `implement` (note: Worktree looks up `implement` in the route, not `worktree`, because it orchestrates Implement).

For quick-fix pipeline (no Worktree in route), Plan invokes Implement directly — Implement asks review depth/mode and presents its own batch gate.

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Mechanical tasks (1-2 files, clear spec) | Fast/cheap model (haiku) |
| Integration tasks (multi-file, pattern matching) | Standard model (sonnet) |
| Architecture/design/review | Most capable model (opus) |

## Task Tracking (TodoWrite)

Create granular tasks for each step:

1. Analyze task dependencies
2. Determine execution mode
3. Present parallelization plan
4. Create worktrees
5. Run baseline tests
6. Dispatch tasks to Implement

Mark each task in_progress when starting, completed when done.

## Red Flags — STOP

- Dispatching parallel tasks that touch overlapping files
- Skipping baseline tests because "they passed last time"
- Creating worktrees on main/master without a feature branch
- Dispatching before user approves parallelization plan
- Re-asking review depth/mode during fix-task dispatch (reuse from config.md)
- Proceeding after BLOCKED status without changing approach
- Dispatching a task whose dependencies haven't completed

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "These tasks are independent, skip the dependency analysis" | File overlap is the real risk. Analyze every time. |
| "Baseline tests failed but they're probably flaky" | Present to user. They decide, not you. |
| "Sequential is fine, skip parallelization analysis" | Missing parallelization wastes time. Analyze once, execute efficiently. |
| "The plan already analyzed dependencies, I can skip" | Plan dependencies are logical. Worktree checks file-level overlap — different analysis. |
| "Single task, skip the parallelization plan" | Single tasks still get a parallelization plan (trivial but consistent). |

## Worked Example — Good

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Hybrid

## Dependency Analysis

| Task | Dependencies | Files | Parallel Group |
|------|-------------|-------|----------------|
| Task 1: Auth types + DB schema | none | `src/types/auth.ts`, `prisma/schema.prisma` | Group 1 |
| Task 2: API middleware | none | `src/middleware/auth.ts`, `src/middleware/rate-limit.ts` | Group 1 |
| Task 3: Auth endpoints | Task 1, Task 2 | `src/routes/auth.ts`, `src/routes/auth.test.ts` | Group 2 |
| Task 4: Profile endpoints | Task 1 | `src/routes/profile.ts`, `src/routes/profile.test.ts` | Group 2 |

## Execution Order

Tasks 1 and 2 run in parallel (no file overlap). Tasks 3 and 4 wait for their dependencies but can run in parallel with each other (no file overlap between them).

## Branch Map

| Task | Branch |
|------|--------|
| task-01 | qrspi/user-auth/task-01 |
| task-02 | qrspi/user-auth/task-02 |
| task-03 | qrspi/user-auth/task-03 |
| task-04 | qrspi/user-auth/task-04 |
```

## Worked Example — Bad

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Parallel

All tasks run in parallel.

| Task | Branch |
|------|--------|
| task-01 | qrspi/user-auth/task-01 |
| task-02 | qrspi/user-auth/task-02 |
| task-03 | qrspi/user-auth/task-03 |
```

**Why this fails:**
- No dependency analysis — Task 3 depends on Tasks 1 and 2 but runs in parallel
- No file overlap check — Tasks 1 and 3 both modify `src/routes/auth.ts`
- No rationale for execution mode choice
- Missing worktree assignments per task
