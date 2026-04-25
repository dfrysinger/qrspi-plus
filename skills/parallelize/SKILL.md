---
name: parallelize
description: Use when plan.md is approved and the QRSPI pipeline needs a parallelization plan — analyzes task dependencies and file overlap, decides execution mode, produces parallelization.md with a symbolic branch map; hands off to Dispatch
---

# Parallelize (QRSPI Step 7)

**Announce at start:** "I'm using the QRSPI Parallelize skill to analyze task dependencies and produce a parallelization plan."

## Overview

Plan-time artifact for the current phase. Analyze dependencies and file overlap across `tasks/*.md` (or fix-task batches), determine execution mode (sequential/parallel/hybrid), and write `parallelization.md` containing a Dependency Analysis table, a symbolic Branch Map, and (if needed) a Stage Commits table. Get human approval, then hand off to Dispatch — which is the runtime owner of branch creation, worktrees, baseline tests, and the Implement loop.

Parallelize never creates branches, never runs baseline tests, never dispatches Implement. Anything that requires resolving a symbolic base to a real commit happens in Dispatch.

## Why This Skill Is Separate From Dispatch

Earlier QRSPI revisions folded planning and runtime into a single Worktree skill. This created a half-static / half-runtime artifact: the Branch Map's `Base` column referenced stage commits that did not exist at plan time, so the document changed meaning between approval and execution. Splitting Parallelize (plan-time, symbolic) from Dispatch (runtime, concrete) restores QRSPI's "one skill = one artifact + one human gate" symmetry. Parallelize owns `parallelization.md` and the parallelization-plan gate; Dispatch owns the Implement loop and the batch gate.

## Iron Law

```
NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN
```

Parallelize is the skill that produces and gates the plan; Dispatch is the skill that consumes and enforces it.

## Artifact Gating

Required inputs:

- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md` (for fix-task routing)
- `design.md` with `status: approved` (phase definitions)
- `config.md`

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md` against `pipeline`. Parallelize-specific menus:

**If `config.md` is missing:**
1. Re-run Goals to create config.md and set the pipeline mode
2. Abort

**If `pipeline` is missing or invalid (expected `full` or `quick`):**
1. Edit config.md and set `pipeline: full` or `pipeline: quick`
2. Re-run Goals to regenerate config.md
3. Abort

<HARD-GATE>
Do NOT mark `parallelization.md` approved while parallel groups overlap on files.
Do NOT include forward-only dependencies (task-N depending on task-M where M > N within a sequential chain) in the Dependency Analysis.
Do NOT name a Base in the Branch Map that the Branch Model does not authorize (see Branch Model below).
This applies regardless of how simple the phase appears.
</HARD-GATE>

## Execution Modes

| Mode | When | Branch Map shape |
|------|------|------------------|
| Sequential | Tasks form a chain (A→B→C) | Each task's base is the previous task's tip |
| Parallel | Tasks are independent and file-disjoint | Every task in the group shares the group's base |
| Hybrid | Mix of independent and dependent tasks | Parallel groups share a base; downstream groups fork from a stage commit, a single prior tip, or `task-00` per the Branch Model |

## Branch Model (Symbolic — Resolved by Dispatch)

`parallelization.md` records every task's `Base` as a **symbolic** reference. Dispatch resolves each symbolic reference to a concrete commit at runtime — including creating stage commits when needed.

1. **Feature branch:** `qrspi/{slug}` (e.g., `qrspi/user-auth`). Created by Dispatch from the current branch (typically `main`) at the start of the first phase. For subsequent phases, the feature branch already exists.
2. **Task branches — base depends on execution mode:**
   - **Terminology — Parallel Group vs Dispatch Wave.** A *parallel group* is a set of tasks that share a base AND have no file overlap; group membership is purely a base-and-disjointness statement, not a dispatch-ordering statement. A *dispatch wave* is the set of tasks Dispatch fires concurrently at a given moment; a wave can contain multiple parallel groups (each with its own base), provided no inter-group logical dependency or file overlap exists. Group numbering does not imply dispatch ordering — concurrency is governed by inter-group dependencies, not by group numbers.
   - **Parallel group:** Every task in the group shares the group's *base tip* (see Hybrid below for groups beyond Group 1; Group 1's base is the feature branch tip). Tasks in a parallel group are independent by construction (no file overlap, no logical dependency).
   - **Sequential chain:** Task-N's base is task-(N-1)'s tip — *not* the feature branch. This is required because sequential dependencies mean task-N imports types/factories/actions/migrations introduced by task-(N-1), and the feature branch does not yet contain task-(N-1)'s work (Integrate runs once at phase end, not per-task).
   - **Hybrid (multi-parent):** When a downstream task or group depends on more than one task from a prior parallel group, the symbolic base is `stage-after-G{N}`. Dispatch creates the intermediate stage commit `qrspi/{slug}/stage-after-G{N}` by merging the prior group's tips into a temporary branch; the next group then forks from that commit. Stage branches are scratch infrastructure created by Dispatch; their lifecycle end (merge semantics + cleanup) is Integrate's concern — see `integrate/SKILL.md` → `Merge Strategy`.
   - **Single-parent across groups:** When a downstream task depends on exactly one task from a prior group, name that task's tip directly as the base — no stage commit needed.
   - **Baseline fix (`task-00`) interaction:** When Dispatch's baseline tests fail and the user chooses Auto-fix (see `dispatch/SKILL.md` → "Baseline Tests"), `task-00` is injected as a phase-level predecessor. `task-00`'s base is the feature branch tip; every other task in the phase then takes `task-00`'s tip as its base (or as one of its parents in the multi-parent case). This injection happens at runtime — Parallelize does not anticipate it. Dispatch persists the injection by appending a `task-00` row to the Branch Map *and* writing a `## Runtime Adjustments` section to `parallelization.md` that lists every task whose effective base changed; the original Branch Map rows are not rewritten. Readers (human or agent) reconstruct effective bases by reading the Branch Map and overlaying `## Runtime Adjustments`.
   - **Re-fork semantics (re-run, fix-round, replan):** Once a task branch exists, it is canonical for that task. Implementer-fix-round dispatches reuse the existing branch and add commits. Re-forking only happens at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset. Never re-fork an existing task branch silently — downstream task branches that descend from it would be invalidated.
   - **Symbolic base vocabulary** (the only values allowed in the `Base` column):
     - `feature branch tip` — the tip of `qrspi/{slug}` at runtime
     - `task-NN tip` — the tip of `qrspi/{slug}/task-NN` (for single-parent forks across groups, or sequential-chain predecessors)
     - `stage-after-G{N}` — the stage commit Dispatch creates by merging Group N's leaves before forking the next group
     - `task-00 tip` — the tip of the baseline-fix branch (only after Dispatch injects `task-00`)
   - Branch naming (informational — Dispatch creates the branches): `qrspi/{slug}/task-NN`; stage branches `qrspi/{slug}/stage-after-G{N}`.
3. **Merge target:** Integrate merges all task branches into the feature branch **once at phase end**, not per-task. The feature branch only changes via Integrate. (See `integrate/SKILL.md` → "Merge Strategy" for how Integrate handles dependency-ordered merges and stage-commit dedup.)
4. **PR target:** Test creates the PR from the feature branch to the base branch.

> **Why the base-naming rule matters.** A common misread is *"all task branches always fork from the feature branch."* That works for parallel-only phases but breaks sequential dependencies — task-N's worktree would start without task-(N-1)'s code. The correct rule is base-from-feature-tip for Group 1 parallel members, base-from-previous-tip for sequential-chain members, base-from-stage-commit when a group has multi-parent dependencies, base-from-task-NN-tip when a downstream task has a single prior-group parent, and base-from-task-00-tip after a baseline fix is injected. Parallelize records the symbolic name; Dispatch resolves it to a concrete commit and creates stage commits as needed.

## Process Steps

1. Identify current phase's tasks from `plan.md` phase definitions
2. For each task, list dependencies and files-touched (read each `tasks/task-NN.md` or `fixes/{type}-round-NN/*.md`)
3. Group tasks into parallel groups (independent + file-disjoint share a group; otherwise separate groups)
4. Determine execution mode (sequential / parallel / hybrid) — pick the simplest mode the dependency graph supports
5. For each group, decide its symbolic base per the Branch Model. For multi-parent dependencies, name a stage commit (`stage-after-G{N}`); for single prior-group parents, name that task's tip; for sequential chains, name the previous task's tip.
6. Compute dispatch waves: Wave 1 contains all groups that depend only on the feature branch tip; subsequent waves contain groups whose dependencies are satisfied by completed prior waves. Multiple groups can share a wave when they have no inter-group dependency or file overlap.
7. Write `parallelization.md` with the required sections (Dependency Analysis table, Branch Map table, Stage Commits table if any, Execution Order narrative)
8. Render the Mermaid dependency graph into the same file (do not paste the diagram into the terminal — the user opens the file to view it)
9. Present the plan to the user for approval

## Artifact

`parallelization.md` — written with `status: draft` in YAML frontmatter. Required sections:

- **Execution Mode** — sequential / parallel / hybrid with one-sentence rationale
- **Dependency Analysis** — table with columns: Task / Dependencies / Files / Parallel Group
- **Branch Map** — table with columns: Task / Branch / Base. The `Base` column uses *only* the symbolic vocabulary defined in the Branch Model (`feature branch tip`, `task-NN tip`, `stage-after-G{N}`, `task-00 tip`). Do not embed concrete commit hashes — Dispatch resolves these at runtime.
- **Stage Commits** — table (only present when any group has multi-parent dependencies) with columns: Stage branch / Composition / Created before
- **Execution Order** — narrative describing the dispatch waves (which groups fire concurrently, what gates the next wave)
- **Mermaid dependency graph** — written inline in the file

`review_depth` and `review_mode` are runtime concerns and live in `config.md` (written by Dispatch at phase start), not in `parallelization.md`.

## Human Gate

Write the Mermaid dependency graph into `parallelization.md` — do not paste the diagram into the terminal. Tell the user: "Parallelization plan written to `parallelization.md` — open it to view the dependency graph."

In the terminal, present the branch map and execution mode as plain text, e.g.:

```
Execution mode: Hybrid

Branch map (symbolic — Dispatch resolves at runtime):
  task-01  →  qrspi/{slug}/task-01   base: feature branch tip
  task-02  →  qrspi/{slug}/task-02   base: feature branch tip
  task-03  →  qrspi/{slug}/task-03   base: stage-after-G1

Parallel Group 1: task-01, task-02 (no file overlap)
Group 2: task-03 (depends on task-01 + task-02 → stage-after-G1)
```

On approval, write `status: approved` in frontmatter and commit (artifact + review file).

On rejection, write the user's feedback to `feedback/parallelize-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), revise the plan, and re-present.

## Review Round

After writing `parallelization.md` (and after every revision), run one review round per the standard QRSPI review-round flow (see `using-qrspi/SKILL.md` → "Review Round Flow"):

1. Claude review subagent — checks for: file-overlap inside any parallel group, symbolic-base vocabulary violations, hybrid scheme that misses a needed stage commit, dispatch-wave ordering that ignores a dependency, missing required sections, mismatch between Dependency Analysis and Branch Map, mismatch between current-phase tasks and `plan.md` phase definitions.
2. Codex review (if `config.md` has `codex_reviews: true`) — same criteria, second opinion.
3. Apply fixes; loop until clean (default) or present at user request.

The orchestrating skill writes findings to `reviews/parallelize-review.md`.

## Terminal State

Recommend compaction: "Parallelization plan approved. This is a good point to compact context before dispatch (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `parallelize` (in the standard full-pipeline route, this is `dispatch`).

## Task Tracking (TodoWrite)

Granular TodoWrite items covering the user-visible Process Steps. Numbering below is local TodoWrite enumeration; each item names the Process Step it covers.

1. Read tasks and analyze dependencies (covers Process Steps 1–2)
2. Group into parallel groups, decide execution mode (covers Process Steps 3–4)
3. Assign symbolic bases and dispatch waves (covers Process Steps 5–6)
4. Write parallelization.md (covers Process Steps 7–8)
5. Run review round (Claude + Codex if enabled)
6. Present parallelization plan (covers Process Step 9)

Mark each task in_progress when starting, completed when done.

## Red Flags — STOP

- A parallel group has tasks that touch overlapping files
- A `Base` column entry is something other than the four symbolic values defined in the Branch Model (no commit hashes, no improvised names)
- The Branch Map names a stage commit but no Stage Commits table exists
- A task is placed in Wave N but one of its dependencies is in Wave N or later
- `parallelization.md` is marked approved while a group has unresolved file overlap
- Embedding concrete commit hashes — that is Dispatch's job at runtime
- Including baseline-fix `task-00` in the initial Branch Map (it does not yet exist; Dispatch decides whether to inject it)
- Asking review depth or review mode here — those are runtime questions Dispatch owns

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "These tasks are independent, skip the dependency analysis" | File overlap is the real risk. Analyze every time, even when the phase looks trivial. |
| "Sequential is fine, skip parallelization analysis" | Missing parallelization wastes time downstream. Analyze once, dispatch efficiently. |
| "The plan already analyzed dependencies, I can skip" | Plan dependencies are logical. Parallelize checks file-level overlap — different analysis. |
| "Single task, skip the parallelization plan" | Single-task phases still get a parallelization plan (trivial but consistent — Dispatch reads it as the source of truth). |
| "I'll record the actual stage commit hash so Dispatch doesn't have to compute it" | Stage commits don't exist yet at plan time. The symbolic name is the contract; Dispatch resolves it. |

## Worked Example — Good

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Hybrid

Rationale: Tasks 1 and 2 are independent (file-disjoint) so they share Group 1. Task 3 depends on both → stage-after-G1. Task 4 depends only on Task 1 → forks directly from task-01.

## Dependency Analysis

| Task | Dependencies | Files | Parallel Group |
|------|-------------|-------|----------------|
| Task 1: Auth types + DB schema | none | `src/types/auth.ts`, `prisma/schema.prisma` | Group 1 (base: feature branch tip) |
| Task 2: API middleware | none | `src/middleware/auth.ts`, `src/middleware/rate-limit.ts` | Group 1 (base: feature branch tip) |
| Task 3: Auth endpoints | Task 1, Task 2 | `src/routes/auth.ts`, `src/routes/auth.test.ts` | Group 2 (base: stage-after-G1, multi-parent) |
| Task 4: Profile endpoints | Task 1 | `src/routes/profile.ts`, `src/routes/profile.test.ts` | Group 3 (base: task-01 tip, single-parent) |

## Execution Order

**Wave 1:** Tasks 1 and 2 dispatch concurrently inside Group 1 (shared base = feature branch tip; no file overlap). Once both finish, Dispatch creates the stage commit `stage-after-G1` (merge of task-01 + task-02 tips).

**Wave 2:** Group 2 (Task 3) forks from `stage-after-G1`. Group 3 (Task 4) forks directly from task-01's tip (single-parent shortcut — no stage commit needed). Both groups dispatch in the same wave because they have no inter-group file overlap and no logical dependency on each other.

## Branch Map

| Task | Branch | Base |
|------|--------|------|
| task-01 | qrspi/user-auth/task-01 | feature branch tip |
| task-02 | qrspi/user-auth/task-02 | feature branch tip |
| task-03 | qrspi/user-auth/task-03 | stage-after-G1 |
| task-04 | qrspi/user-auth/task-04 | task-01 tip |

## Stage Commits

| Stage branch | Composition | Created before |
|--------------|-------------|----------------|
| qrspi/user-auth/stage-after-G1 | merge(task-01, task-02) | task-03 worktree creation |
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

**Why this fails:** missing dependency analysis (Task 3 needs 1+2 but shown parallel); no file-overlap check (Tasks 1 and 3 both modify `src/routes/auth.ts`); no execution-mode rationale; missing Branch Map `Base` column so Dispatch has no way to know how to fork.

## Iron Laws — Final Reminder

The two override-critical rules for Parallelize, restated at end:

1. **NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN.** Parallelize produces and gates the plan; Dispatch consumes and enforces it. Approving a plan with unresolved file overlap inside any parallel group breaks the dispatch contract.

2. **The `Base` column uses ONLY symbolic vocabulary** — `feature branch tip`, `task-NN tip`, `stage-after-G{N}`, `task-00 tip`. No concrete commit hashes, no improvised names. Dispatch resolves at runtime; Parallelize records only the symbolic contract.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
