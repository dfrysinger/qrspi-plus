---
status: draft
question_ids: [6, 14]
research_type: codebase
---

# Q6, Q14: Branch Map Table Structure and Reviewer Linting Rules

## Summary

**TL;DR:** The Branch Map table in `skills/parallelize/SKILL.md` has exactly three columns — `Task`, `Branch`, `Base` — with one row per task and no Wave column (wave assignment lives in the separate Dependency Analysis table and in an Execution Order prose section). The only reviewer that enforces Branch Map rules is `agents/qrspi-parallelize-reviewer.md`; `agents/qrspi-plan-reviewer.md` and all files under `skills/plan/` contain zero Branch Map references.

**Key findings:**
- Branch Map table is always three columns: `Task | Branch | Base` — consistent across all three worked examples in `skills/parallelize/SKILL.md`.
- Wave information is presented **both** in the `Wave` column of the Dependency Analysis table (as a cell value like `Wave 1 (base: feature branch tip)`) **and** in a separate `## Execution Order` section written as bold-prefaced prose (`**Wave 1:** ...`, `**Wave 2:** ...`).
- The Branch Map itself has no Wave column; wave assignment is only in the Dependency Analysis table.
- All Branch Map linting rules are declared in `agents/qrspi-parallelize-reviewer.md` (lines 28–34). No Branch Map rules exist in `agents/qrspi-plan-reviewer.md` or anywhere under `skills/plan/`.
- The parallelize reviewer enforces: symbolic-base vocabulary, required sections presence, Dependency Analysis vs. Branch Map consistency, and row-completeness (every plan task must appear as a Branch Map row). There are **no explicit column-set ordering rules, no header-ordering rules, and no wave-numbering convention rules** beyond what is in the skill's Branch Model definition.

**Surprises:** `agents/qrspi-plan-reviewer.md` enforces zero rules about the Branch Map — it does not mention `parallelization.md` or the Branch Map at all. The question's phrase "Plan-step reviewer" does not map to the plan reviewer agent; the Branch Map is exclusively owned by the parallelize reviewer agent.

**Caveats:** Only `agents/qrspi-parallelize-reviewer.md` and `agents/qrspi-plan-reviewer.md` were examined in detail for Branch Map linting. All other agents under `agents/` were scanned by grep and confirmed to contain no `Branch Map` text except the parallelize reviewer. `skills/plan/SKILL.md` was scanned by grep and confirmed to contain no Branch Map references.

---

## Full findings

### Q6: Branch Map table columns, rows, and wave/execution-order presentation in `skills/parallelize/SKILL.md`

#### Branch Map table — invariant column set

All three worked examples in `skills/parallelize/SKILL.md` define the Branch Map table identically:

```
| Task | Branch | Base |
|------|--------|------|
```

Three columns, in this fixed order: **Task**, **Branch**, **Base**.

Source: `skills/parallelize/SKILL.md` line 132 (normative spec) and lines 351–356, 397–402, 449–455 (worked examples).

The artifact spec at line 132 states:
> **Branch Map** — table with columns: Task / Branch / Base. The `Base` column uses *only* the symbolic vocabulary defined in the Branch Model.

#### Branch Map rows in each worked example

**Worked Example — Good** (lines 349–356, slug `user-auth`, 4-task hybrid):

| Task    | Branch                        | Base               |
|---------|-------------------------------|---------------------|
| task-01 | qrspi/user-auth/task-01       | feature branch tip  |
| task-02 | qrspi/user-auth/task-02       | feature branch tip  |
| task-03 | qrspi/user-auth/task-03       | stage-after-W1      |
| task-04 | qrspi/user-auth/task-04       | task-01 tip         |

One row per task; no Wave column; no header row variants.

**Worked Example — Multi-Stage Suffix** (lines 395–402, slug `db-migration`, 4-task hybrid with suffixed stages):

| Task    | Branch                          | Base              |
|---------|---------------------------------|-------------------|
| task-01 | qrspi/db-migration/task-01      | feature branch tip |
| task-02 | qrspi/db-migration/task-02      | feature branch tip |
| task-03 | qrspi/db-migration/task-03      | stage-after-W1a    |
| task-04 | qrspi/db-migration/task-04      | stage-after-W1b    |

**Worked Example — Reference-Gate Wave Termination** (lines 447–455, slug `feature`, 5-task hybrid with reference gate):

| Task    | Branch                    | Base               |
|---------|---------------------------|--------------------|
| task-01 | qrspi/feature/task-01     | feature branch tip |
| task-02 | qrspi/feature/task-02     | feature branch tip |
| task-03 | qrspi/feature/task-03     | stage-after-W1     |
| task-04 | qrspi/feature/task-04     | task-03 tip        |
| task-05 | qrspi/feature/task-05     | task-03 tip        |

Immediately after the Branch Map in this example is the reference-gate note (line 457):
```
Reference gate: task-03 (Adapter contract doc) — dependents waiting: task-04, task-05
```

**Worked Example — Bad** (lines 466–483): The bad example deliberately omits the `Base` column, rendering only two columns (`Task | Branch`). This is explicitly identified as a failure: "missing Branch Map `Base` column so Implement has no way to know how to fork."

#### How wave/execution-order information is currently presented

Wave information appears in **two** locations, using **both** table and prose:

1. **Table — `## Dependency Analysis` section** (`Wave` column): The Dependency Analysis table has 4 columns: `Task | Dependencies | Files | Wave`. The `Wave` cell includes the wave number and base reference, e.g.:
   - `Wave 1 (base: feature branch tip)` — line 338
   - `Wave 2 (base: stage-after-W1, multi-parent)` — line 340
   - `Wave 3 (base: task-01 tip, single-parent)` — line 341
   - `Wave 2 (base: stage-after-W1; reference_gate: true)` — line 435

2. **Prose — `## Execution Order` section**: Each wave is described in a bold-prefaced paragraph, e.g.:
   - `**Wave 1:** Tasks 1 and 2 dispatch concurrently (shared base = feature branch tip; no file overlap). Once both finish, Implement creates the stage commit \`stage-after-W1\`.` — lines 345–346
   - `**Wave 2 and Wave 3 (concurrent):** Wave 2 (Task 3) forks from \`stage-after-W1\`. ...` — lines 347–348

The `## Branch Map` section itself does **not** contain a Wave column. Wave assignment is therefore communicated redundantly: once in the Dependency Analysis table's `Wave` column and once in the Execution Order narrative prose. The Branch Map's `Base` column implicitly encodes wave topology (stage commits signal multi-parent waves; `task-NN tip` signals single-parent downstream waves) but does not name wave numbers.

Wave numbering convention (from lines 72–73, 104–106): Wave numbers (`W1`, `W2`, etc.) are integers assigned in dependency order. Wave 1 contains tasks whose only dependency is the feature branch tip. Wave numbering does not imply dispatch ordering — Implement's runtime rule dispatches every wave whose dependencies are satisfied; concurrency is derived from the dependency graph. The Dependency Analysis table's `Wave` cell uses the format `Wave N (base: <symbolic base>)`.

---

### Q14: Linting rules for the Branch Map table format in `agents/` or `skills/plan/`

#### Which reviewer agent is responsible

The Branch Map is part of `parallelization.md`, not `plan.md`. The reviewer for `parallelization.md` is **`agents/qrspi-parallelize-reviewer.md`**. The plan reviewer (`agents/qrspi-plan-reviewer.md`) does not reference `parallelization.md` or the Branch Map at all (confirmed by grep: zero matches in `qrspi-plan-reviewer.md`).

No files under `skills/plan/` reference the Branch Map (confirmed by grep: zero matches in `skills/plan/SKILL.md`, `skills/plan/owns-defers.md`, `skills/plan/post-approval-split-contract.md`, `skills/plan/smoke-spec.md`, `skills/plan/SKILL.anchors.json`).

#### Branch Map linting rules in `agents/qrspi-parallelize-reviewer.md`

All rules are declared at `agents/qrspi-parallelize-reviewer.md` lines 28–34 under **§ Step 2 — apply checks — Parallelize-specific quality checks**:

| Rule | Location | What it enforces |
|------|----------|-----------------|
| **File-overlap inside any Wave** | line 28 | Tasks within the same Wave must not write to the same file; violation → `severity: high` |
| **Symbolic-base vocabulary** | line 29 | Branch Map `Base` values must be exactly: `feature branch tip`, `task-NN tip`, `stage-after-W{N}` (unsuffixed, single stage), `stage-after-W{N}{suffix}` (e.g., `stage-after-W2a`), `task-00 tip` (after baseline-fix injection only). Hyphenated (`feature-branch-tip`) or integer-suffixed (`stage-1`, `task-NN-tip`) variants → finding with `change_type: style`. No literal commit SHAs in the plan-time document. |
| **Hybrid scheme stage-commit completeness** | line 30 | If a Wave has multi-parent dependencies, verify a stage commit is planned; no hybrid scheme that leaves a merge gap. |
| **Wave ordering** | line 31 | Wave ordering in the Execution Order narrative must respect all dependencies declared in the Dependency Analysis; no Wave may run a task before its declared prerequisites. |
| **Required sections present** | line 32 | `parallelization.md` must contain: Branch Map, Dependency Analysis (pairwise), Mermaid dependency graph, Execution Order narrative. Any absent section → finding. |
| **Dependency Analysis vs. Branch Map consistency** | line 33 | Dependencies declared in Dependency Analysis must be reflected in Branch Map (task ordering and base assignments); mismatches → findings. |
| **Completeness check (mandatory)** | line 34 | Every current-phase task from `companion_plan` must appear: (a) as a node in the Mermaid dependency graph; (b) as a row in the Branch Map; (c) covered by pairwise file-overlap analysis. A task missing from (a), (b), or (c) → `severity: high`, `change_type: correctness`. |

#### What is NOT enforced

The parallelize reviewer prompt does **not** enforce:
- **Column set ordering** — the required column sequence `Task | Branch | Base` is specified in the skill (`skills/parallelize/SKILL.md` line 132) but there is no explicit column-ordering lint rule in the reviewer.
- **Header text/format** — no rule checks that column headers are spelled correctly or capitalized consistently.
- **Wave-numbering convention** — no explicit rule enforces the `W1`, `W2`, `W{N}` numbering format in the Wave column of the Dependency Analysis, or the `stage-after-W{N}` integer format. The vocabulary check in line 29 implicitly constrains the form of stage-commit names in the `Base` column but does not explicitly enforce the integer-only wave index format.
- **Required cells** — no rule checks for blank/missing individual cells within an otherwise-present Branch Map row.

#### Additional source: `skills/parallelize/SKILL.md` Red Flags section

The skill's own `## Red Flags — STOP` section (lines 298–309) lists process-level checks that overlap with reviewer rules:
- `A \`Base\` column entry is something other than the four symbolic values defined in the Branch Model` (line 301)
- `The Branch Map names a stage commit but no Stage Commits table exists` (line 302)
- `A task is placed in Wave N but one of its dependencies is in Wave N or later` (line 303)
- `` `parallelization.md` contains a task with `reference_gate: true` but no `Reference gate: task-NN ...` note appears after the Branch Map table `` (line 308)
- `A dependent of a reference-gated task is scheduled in the same Wave as the gate` (line 309)

These are documented as Parallelize-author self-checks; the reviewer enforces the same checks independently from `agents/qrspi-parallelize-reviewer.md`.
