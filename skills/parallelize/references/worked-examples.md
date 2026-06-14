## Worked Example — Good

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Hybrid

Rationale: Tasks 1 and 2 are independent (file-disjoint) so they share Wave 1. Task 3 depends on both → stage-after-W1. Task 4 depends only on Task 1 → forks directly from task-01.

## Dependency Analysis

| Task | Dependencies | Files | Wave |
|------|-------------|-------|------|
| Task 1: Auth types + DB schema | none | `src/types/auth.ts`, `prisma/schema.prisma` | Wave 1 (base: feature branch tip) |
| Task 2: API middleware | none | `src/middleware/auth.ts`, `src/middleware/rate-limit.ts` | Wave 1 (base: feature branch tip) |
| Task 3: Auth endpoints | Task 1, Task 2 | `src/routes/auth.ts`, `src/routes/auth.test.ts` | Wave 2 (base: stage-after-W1, multi-parent) |
| Task 4: Profile endpoints | Task 1 | `src/routes/profile.ts`, `src/routes/profile.test.ts` | Wave 3 (base: task-01 tip, single-parent) |

## Branch Map

### Wave 1

| Task | Branch | Base |
|------|--------|------|
| task-01 | qrspi/user-auth/task-01 | feature branch tip |
| task-02 | qrspi/user-auth/task-02 | feature branch tip |

### Wave 2

| Task | Branch | Base |
|------|--------|------|
| task-03 | qrspi/user-auth/task-03 | stage-after-W1 |

### Wave 3

| Task | Branch | Base |
|------|--------|------|
| task-04 | qrspi/user-auth/task-04 | task-01 tip |

## Stage Commits

| Stage branch | Composition | Created before |
|--------------|-------------|----------------|
| qrspi/user-auth/stage-after-W1 | merge(task-01, task-02) | task-03 worktree creation |
```

## Worked Example — Multi-Stage Suffix

When one Wave feeds two or more disjoint downstream dependency groups, Parallelize emits one suffixed stage commit per group using the `stage-after-W{N}{suffix}` grammar (`a`, `b`, `c`, …):

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Hybrid

Rationale: Tasks 1 and 2 are independent and share Wave 1. Task 3 depends on Task 1 only; Task 4 depends on Task 2 only. Because the two downstream Waves have different parent sets from Wave 1, two partial stage commits (stage-after-W1a from task-01, stage-after-W1b from task-02) are emitted instead of a full merge, keeping each downstream Wave's base minimal.

## Dependency Analysis

| Task | Dependencies | Files | Wave |
|------|-------------|-------|------|
| Task 1: DB schema | none | `prisma/schema.prisma` | Wave 1 (base: feature branch tip) |
| Task 2: API types  | none | `src/types/api.ts` | Wave 1 (base: feature branch tip) |
| Task 3: Schema migrations | Task 1 | `src/db/migrate.ts`, `tests/migrate.test.ts` | Wave 2 (base: stage-after-W1a, single-parent from W1) |
| Task 4: API routes | Task 2 | `src/routes/api.ts`, `tests/api.test.ts` | Wave 2 (base: stage-after-W1b, single-parent from W1) |

## Branch Map

### Wave 1

| Task | Branch | Base |
|------|--------|------|
| task-01 | qrspi/db-migration/task-01 | feature branch tip |
| task-02 | qrspi/db-migration/task-02 | feature branch tip |

### Wave 2

| Task | Branch | Base |
|------|--------|------|
| task-03 | qrspi/db-migration/task-03 | stage-after-W1a |
| task-04 | qrspi/db-migration/task-04 | stage-after-W1b |

## Stage Commits

| Stage branch | Composition | Created before |
|--------------|-------------|----------------|
| qrspi/db-migration/stage-after-W1a | wrap(task-01) | task-03 worktree creation |
| qrspi/db-migration/stage-after-W1b | wrap(task-02) | task-04 worktree creation |
```

**When to use the suffix form:** use `stage-after-W{N}{suffix}` only when the same Wave index `{N}` produces two or more stage commits for different downstream dependency groups. When a Wave produces exactly one stage commit (the common case), use the unsuffixed `stage-after-W{N}` form.

## Worked Example — Reference-Gate Wave Termination

When a task carries `reference_gate: true`, it terminates its Wave and all dependents land in the next Wave. The canonical `Reference gate:` note appears after the Branch Map:

```markdown
---
status: draft
---

# Parallelization Plan

## Execution Mode: Hybrid

Rationale: Tasks 1 and 2 are independent (Wave 1). Task 3 carries reference_gate: true — it terminates Wave 2 alone; Tasks 4 and 5 (which depend on Task 3) land in Wave 3.

## Dependency Analysis

| Task | Dependencies | Files | Wave |
|------|-------------|-------|------|
| Task 1: Config schema | none | `skills/using-qrspi/SKILL.md` | Wave 1 (base: feature branch tip) |
| Task 2: Prompt utils lib | none | `scripts/lib/llm-prompt-utils.sh` | Wave 1 (base: feature branch tip) |
| Task 3: Adapter contract doc (reference gate) | Task 1, Task 2 | `skills/implement/red-verification-adapters.md` | Wave 2 (base: stage-after-W1; reference_gate: true) |
| Task 4: Adapter scripts | Task 3 | `scripts/red-verify/*.sh` | Wave 3 (base: task-03 tip) |
| Task 5: Dual-mode test-writer | Task 3 | `agents/qrspi-test-writer.md` | Wave 3 (base: task-03 tip) |

## Branch Map

### Wave 1

| Task | Branch | Base |
|------|--------|------|
| task-01 | qrspi/feature/task-01 | feature branch tip |
| task-02 | qrspi/feature/task-02 | feature branch tip |

### Wave 2

| Task | Branch | Base |
|------|--------|------|
| task-03 | qrspi/feature/task-03 | stage-after-W1 |

### Wave 3

| Task | Branch | Base |
|------|--------|------|
| task-04 | qrspi/feature/task-04 | task-03 tip |
| task-05 | qrspi/feature/task-05 | task-03 tip |

Reference gate: task-03 (Adapter contract doc) — dependents waiting: task-04, task-05

## Stage Commits

| Stage branch | Composition | Created before |
|--------------|-------------|----------------|
| qrspi/feature/stage-after-W1 | merge(task-01, task-02) | task-03 worktree creation |
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

**Why this fails:** missing dependency analysis (Task 3 needs 1+2 but shown parallel); no file-overlap check (Tasks 1 and 3 both modify `src/routes/auth.ts`); no execution-mode rationale; missing Branch Map `Base` column so Implement has no way to know how to fork.
