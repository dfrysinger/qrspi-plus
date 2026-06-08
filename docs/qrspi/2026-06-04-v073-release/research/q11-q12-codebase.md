---
status: draft
question_ids: [11, 12]
research_type: codebase
---

# Q11, Q12: Stage Commit Construction and the Implement Skill Branch Model

## Summary

**TL;DR:** Stage commits (`qrspi/{slug}/stage-after-W{N}`) are created by Implement at runtime by merging the current tips of every task branch in a completed Wave into a new temporary branch. No explicit verification of the parent commit set is performed at stage-commit creation time; the only precondition checked is that all tasks in the originating Wave are in a terminal state. The branch model in the implement skill resolves all task-tip SHAs in-memory at dispatch time from the symbolic names recorded in `parallelization.md`'s Branch Map, and explicitly prohibits writing resolved SHAs back to that artifact.

**Key findings:**
- Stage commits are constructed by Implement at runtime as a merge of Wave N's task-branch tips, matching the `Composition` column (`merge(task-01, task-02)` or `wrap(task-NN)`) in the Stage Commits table in `parallelization.md`. (`skills/implement/SKILL.md`:338; `skills/parallelize/SKILL.md`:288–291)
- Creation timing: after every task in a Wave reaches terminal state, before forking any task in a downstream Wave that names the stage commit as its `Base`. (`skills/implement/SKILL.md`:341, 373, 381, 439)
- No git-level or SHA-level verification of the parent commit set is run at stage-commit creation time. The only pre-creation check is that every task in the originating Wave has a terminal per-task status. (`skills/implement/SKILL.md`:425, 439)
- The `Base` column in `parallelization.md`'s Branch Map is **always symbolic** — four allowed values: `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip`. Implement resolves each to a concrete commit in-memory at runtime; resolved SHAs are never written back to `parallelization.md`. (`skills/implement/SKILL.md`:334–341; `skills/parallelize/SKILL.md`:64–87)
- For a stage commit, the parents are exactly the current tips of the named Wave's task branches at the moment of creation. For a single-source stage (`stage-after-W{N}{suffix}` form), the Composition is `wrap(task-NN)`, meaning only that one task's tip is the parent. (`skills/parallelize/SKILL.md`:337–338)
- Symbolic base resolution is layered: Implement reads the Branch Map first, then overlays any `## Runtime Adjustments` section, which records baseline-fix injections (`task-00`) that rebased tasks at runtime. (`skills/implement/SKILL.md`:361, 372, 398–399)
- A file-overlap re-verification is required at runtime even if Parallelize already cleared it, but this applies to parallel task dispatch, not to stage-commit parent set verification. (`skills/implement/SKILL.md`:1416, 1431)

**Surprises:** The stage-commit parent set has no dedicated git-level verification at creation time — the only enforced precondition is that all Wave tasks are in a terminal state before the stage commit is built. There is no check such as `git log` or `git merge-base` to confirm the named task-tip branches point to the expected commits before the merge. The `wrap()` notation in the Stage Commits table is not defined in prose — it appears only in the worked example for the single-parent suffixed-stage case, where it represents a single-parent stage commit (the branch tip of one task).

**Caveats:** The skill files do not specify the exact git command used to create stage commits (no `git merge --no-ff` vs. `git merge --ff` vs. octopus merge specification). The `wrap()` vs. `merge()` distinction in the `Composition` column is only illustrated in worked examples; no explicit prose definition of `wrap()` exists in the skill files read. The integrate skill was examined only for its Merge Strategy section.

## Full findings

### Q11: Stage commit construction during a multi-task wave merge

**Source files:** `skills/implement/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/integrate/SKILL.md`

#### What a stage commit is

A stage commit is a temporary branch (`qrspi/{slug}/stage-after-W{N}`) created by Implement at runtime to serve as the common base for downstream tasks whose `Base` is `stage-after-W{N}` in `parallelization.md`. Stage branches are called "scratch infrastructure" and are deleted by Integrate after it merges all leaf task branches. (`skills/integrate/SKILL.md`:77, 80)

#### When stage commits are created

Stage commits are created in two related places in the implement skill:

1. **Pre-Wave check (Process Steps, Step 6):** Before forking any task in a Wave, Implement walks the Branch Map in Wave-dispatch order and, for every task that names `stage-after-W{N}` as its `Base`, verifies the stage commit branch exists; if not, creates it then. (`skills/implement/SKILL.md`:341, 373)

2. **Post-Wave creation (Wave Dispatch step 6):** After all tasks in a Wave reach a terminal state and before moving to the next Wave, "If the next Wave depends on a stage commit (`stage-after-W{N}`), create it now from the just-completed Wave's tips." (`skills/implement/SKILL.md`:381, 439)

The prose at line 341 states the ordering rule explicitly: "walk the Branch Map in Wave-dispatch order. Before starting a Wave, verify every `stage-after-W{N}` referenced by any task in that Wave exists; if not, create it from the named composition."

#### How the parent set is determined

The parent set of a stage commit is the set of current tips of all task branches named in the `Composition` column of the Stage Commits table in `parallelization.md`. Parallelize writes this table; Implement reads and executes it.

Two Composition forms appear in worked examples:

- **`merge(task-01, task-02)`** — multi-parent merge. Used when a downstream Wave depends on two or more prior tasks. The stage commit has multiple parents (one per named task-tip). Example: `qrspi/user-auth/stage-after-W1` is `merge(task-01, task-02)` created before task-03's worktree creation. (`skills/parallelize/SKILL.md`:290; `skills/implement/SKILL.md`:1398)
- **`wrap(task-NN)`** — single-parent stage. Used in the suffixed form (`stage-after-W{N}{suffix}`) when one Wave emits multiple stage commits for different downstream dependency groups. Each stage commit wraps exactly one prior task-tip. Example: `qrspi/db-migration/stage-after-W1a` is `wrap(task-01)`. (`skills/parallelize/SKILL.md`:337–338)

Implement resolves each `task-NN tip` reference in the Composition to the current tip of `qrspi/{slug}/task-NN` at the moment of stage-commit creation. (`skills/implement/SKILL.md`:337)

#### Verification at creation time

No explicit git-level or SHA-level verification of the parent commit set is specified at stage-commit creation time. The skill prose describes the precondition for creating a stage commit as:

1. All tasks in the originating Wave must be in a per-task terminal state (clean, accepted-with-issues, or unresolved-after-3-fix-cycles). Only after "Wait for every task in the wave to return a per-task terminal status" does the wave proceed to stage-commit creation. (`skills/implement/SKILL.md`:428–439)
2. Wave Dispatch step 1 states: "Verify every task in the wave has its `Base` resolved (and any required stage commit created)." This is a pre-dispatch check ensuring the stage commit exists before forking dependent tasks — it is not a verification of the stage commit's own parent set. (`skills/implement/SKILL.md`:425)

There is no procedure such as checking that `git rev-parse qrspi/{slug}/task-NN` matches the expected commit, or verifying the merge-base, before executing the merge to create the stage commit.

A runtime file-overlap re-verification is required before dispatching parallel tasks, but this applies to inter-task file conflict checking, not to stage-commit parent set validation. (`skills/implement/SKILL.md`:1416)

#### Worked example (from the skill)

From `skills/implement/SKILL.md`:1396–1400:

> **Wave 1.** …Resolve `feature branch tip` to the current tip of `qrspi/user-auth/main`, create worktrees…dispatch both implementer subagents concurrently…Wait for both per-task flows to reach a terminal status.
>
> **Stage commit creation.** Both Wave 1 tasks now in terminal state. Implement sees Wave 2 needs `stage-after-W1`. Create branch `qrspi/user-auth/stage-after-W1` by merging task-01 and task-02 tips. (Composition is documented in `parallelization.md` § Stage Commits.)

#### Lifecycle end

Integrate deletes all stage branches (`qrspi/{slug}/stage-after-W*`) after merging leaf task branches: "Do not merge stage branches directly — they are scratch infrastructure Implement created for downstream forks; merging them separately produces duplicate history with the leaves." (`skills/integrate/SKILL.md`:77, 80)

---

### Q12: Branch model relationship between named task-tip SHAs and stage-commit parents

**Source files:** `skills/implement/SKILL.md` §§ Branch Model — Runtime Resolution (Full Pipeline), Common Rationalizations; `skills/parallelize/SKILL.md` § Branch Model (Symbolic — Resolved by Implement)

#### The symbolic/runtime split

The branch model is explicitly divided between plan-time (Parallelize) and runtime (Implement):

- **Parallelize** records only symbolic references in the `Base` column of `parallelization.md`'s Branch Map. No concrete commit hashes are written at plan time. ("Do not embed concrete commit hashes — Implement resolves these at runtime." — `skills/parallelize/SKILL.md`:138)
- **Implement** resolves each symbolic reference to a concrete commit in-memory at runtime, before forking each task's worktree or creating a stage commit. (`skills/implement/SKILL.md`:330–341)

#### The symbolic vocabulary and its runtime resolution

From `skills/implement/SKILL.md`:334–339 (the full resolution table):

| Symbolic base | Runtime resolution |
|---------------|--------------------|
| `feature branch tip` | The current tip of `qrspi/{slug}/main` |
| `task-NN tip` | The current tip of `qrspi/{slug}/task-NN` (must already exist before forking — enforced by wave ordering) |
| `stage-after-W{N}` | A new branch `qrspi/{slug}/stage-after-W{N}` created by merging the tips of every task in Wave N (composition listed in `parallelization.md` § Stage Commits). Created on demand, before forking any task whose `Base` names it. |
| `task-00 tip` | The current tip of `qrspi/{slug}/task-00` (only valid after baseline-fix injection) |

For stage commits specifically: the parent set = the tips of the Wave N task branches at the moment of creation. Wave ordering enforces that those branches exist and are in a terminal state before the stage commit is created. (`skills/implement/SKILL.md`:337, 341)

#### The four allowed symbolic base values

Only four symbolic values are permitted in the `Base` column. (`skills/parallelize/SKILL.md`:81–86; `skills/implement/SKILL.md`:338)

The `stage-after-W{N}{suffix}` suffixed form (`stage-after-W2a`, `stage-after-W2b`, …) is an extension for Waves emitting multiple stage commits for different downstream dependency groups. The unsuffixed form is the canonical choice when a Wave produces only one stage commit. (`skills/parallelize/SKILL.md`:85, 87)

#### In-memory resolution only — no SHA write-back

A specific anti-pattern in the Common Rationalizations section (`skills/implement/SKILL.md`:1435) directly forbids persisting resolved SHAs:

> "I can resolve `stage-after-W1` to a hash and write it back into `parallelization.md`" → "The symbolic name is the contract; appending a hash drifts the artifact away from its approved form. Resolve in-memory."

All resolution is therefore ephemeral, held in main chat's in-session context. A session restart requires re-resolving all bases from scratch by reading the Branch Map and any `## Runtime Adjustments` section. (`skills/implement/SKILL.md`:361, 398–399)

#### Runtime Adjustments overlay

When Implement injects a baseline-fix `task-00` because baseline tests fail, it:
1. Appends a `task-00` row to the Branch Map in `parallelization.md`.
2. Appends a `## Runtime Adjustments` section recording which tasks had their effective base changed (e.g., `task-NN: new base = task-00 tip`).

This does not rewrite existing Branch Map rows. On every subsequent dispatch, Implement reads the Branch Map first, then overlays `## Runtime Adjustments` overrides. For the stage-commit case, the adjustment can state `task-NN: new base = stage-after-W{N} re-merged on top of task-00 tip`. (`skills/implement/SKILL.md`:372, 398–399)

#### Why task-tip must already exist before forking

The implement skill's branch model states that `task-NN tip` "must already exist before forking — enforce wave ordering." This is enforced by executing Waves in ascending-N order and only dispatching a dependent Wave after all tasks in the predecessor Wave are in terminal state. A common-rationalization entry flags dispatching a task whose dependencies haven't completed as a Red Flag. (`skills/implement/SKILL.md`:337, 1422)

#### Parallelize's perspective

`skills/parallelize/SKILL.md`:74–77 describes the base-assignment rules that produce the `Base` column values for stage commits:

> **Hybrid (multi-parent):** When a downstream task or Wave depends on more than one task from a prior Wave, the symbolic base is `stage-after-W{N}`. Implement creates the intermediate stage commit `qrspi/{slug}/stage-after-W{N}` by merging the prior Wave's tips into a temporary branch; the next Wave then forks from that commit.
>
> **Single-parent across Waves:** When a downstream task depends on exactly one task from a prior Wave, name that task's tip directly as the base — no stage commit needed.

The rationale note at line 91 summarizes the full base-naming rule:

> The correct rule is base-from-feature-tip for Wave 1 parallel members, base-from-previous-tip for sequential-chain members, base-from-stage-commit when a Wave has multi-parent dependencies, base-from-task-NN-tip when a downstream task has a single prior-Wave parent, and base-from-task-00-tip after a baseline fix is injected. Parallelize records the symbolic name; Implement resolves it to a concrete commit and creates stage commits as needed.
