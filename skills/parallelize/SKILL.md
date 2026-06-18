---
name: parallelize
description: Use when plan.md is approved and the QRSPI pipeline needs a parallelization plan — analyzes task dependencies and file overlap, decides execution mode, produces parallelization.md with a symbolic branch map; hands off to Implement
---

# Parallelize (QRSPI Step 8)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Parallelize skill to analyze task dependencies and produce a parallelization plan."

## Overview

Plan-time artifact for the current phase. Analyze dependencies and file overlap across `tasks/*.md` (or fix-task batches), determine execution mode (sequential/parallel/hybrid), and write `parallelization.md` containing a Dependency Analysis table, a symbolic Branch Map, and (if needed) a Stage Commits table. Get human approval, then hand off to Implement — which is the runtime owner of branch creation, worktrees, baseline tests, and the per-task orchestration loop.

Parallelize never creates branches, never runs baseline tests, never dispatches per-task subagents. Anything that requires resolving a symbolic base to a real commit happens in Implement.

## Why This Skill Is Separate From Implement

Earlier QRSPI revisions folded planning and runtime into a single Worktree skill. This created a half-static / half-runtime artifact: the Branch Map's `Base` column referenced stage commits that did not exist at plan time, so the document changed meaning between approval and execution. Splitting Parallelize (plan-time, symbolic) from Implement (runtime, concrete) restores QRSPI's "one skill = one artifact + one human gate" symmetry. Parallelize owns `parallelization.md` and the parallelization-plan gate; Implement owns the per-task orchestration loop and the batch gate.

## Iron Law

```
NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN
```

Parallelize is the skill that produces and gates the plan; Implement is the skill that consumes and enforces it.

## Parallelize OWNS / Parallelize DEFERS

!cat skills/parallelize/owns-defers.md

## Artifact Gating

Required inputs:

- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md` (for fix-task routing)
- `phasing.md` with `status: approved` (phase definitions and slice ownership)
- `config.md`

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Parallelize validates `pipeline`, `route`, and (when `pipeline: quick`) `question_budget`.

<HARD-GATE>
Do NOT mark `parallelization.md` approved while Waves overlap on files.
Do NOT include forward-only dependencies (task-N depending on task-M where M > N within a sequential chain) in the Dependency Analysis.
Do NOT name a Base in the Branch Map that the Branch Model does not authorize (see Branch Model below).
This applies regardless of how simple the phase appears.
</HARD-GATE>

## Execution Modes

| Mode | When | Branch Map shape |
|------|------|------------------|
| Sequential | Tasks form a chain (A→B→C) | Each task's base is the previous task's tip |
| Parallel | Tasks are independent and file-disjoint | Every task in the Wave shares the Wave's base |
| Hybrid | Mix of independent and dependent tasks | Waves share a base; downstream Waves fork from a stage commit, a single prior tip, or `task-00` per the Branch Model |

## Branch Model (Symbolic — Resolved by Implement)

`parallelization.md` records every task's `Base` as a **symbolic** reference. Implement resolves each symbolic reference to a concrete commit at runtime — including creating stage commits when needed.

1. **Feature branch:** `qrspi/{slug}/main` (e.g., `qrspi/user-auth/main`). Created by Implement from the current branch (typically `main`) at the start of the first phase. For subsequent phases, the feature branch already exists.

   **Why `/main`, not bare `qrspi/{slug}`** (F-14): git stores refs hierarchically and cannot have both a leaf ref `qrspi/{slug}` and a namespace `qrspi/{slug}/...` simultaneously. Naming the feature branch `qrspi/{slug}/main` makes it a sibling of the task branches under the `qrspi/{slug}/` namespace — all four kinds of branches (feature `main`, `task-NN`, `task-NNa`, `stage-after-W{N}`) coexist as namespace siblings. Bare `qrspi/{slug}` would deadlock the very first task-branch creation with `fatal: cannot lock ref ... 'refs/heads/qrspi/{slug}' exists`. <!-- id-hygiene-exempt -->
2. **Task branches — base depends on execution mode:**
   - **Wave:** A set of tasks that share a base AND have no file overlap. Wave numbering does not imply dispatch ordering — Implement's runtime rule is "dispatch every Wave whose dependencies are satisfied each tick."
   - **Parallel:** Every task in the Wave shares the Wave's *base tip* (see Hybrid below for Waves beyond Wave 1; Wave 1's base is the feature branch tip). Tasks in a Wave are independent by construction (no file overlap, no logical dependency).
   - **Sequential chain:** Task-N's base is task-(N-1)'s tip — *not* the feature branch. This is required because sequential dependencies mean task-N imports types/factories/actions/migrations introduced by task-(N-1), and the feature branch does not yet contain task-(N-1)'s work (Integrate runs once at phase end, not per-task).
   - **Hybrid (multi-parent):** When a downstream task or Wave depends on more than one task from a prior Wave, the symbolic base is `stage-after-W{N}`. Implement creates the intermediate stage commit `qrspi/{slug}/stage-after-W{N}` by merging the prior Wave's tips into a temporary branch; the next Wave then forks from that commit. Stage branches are scratch infrastructure created by Implement; their lifecycle end (merge semantics + cleanup) is Integrate's concern — see `integrate/SKILL.md` → `Merge Strategy`.
   - **Single-parent across Waves:** When a downstream task depends on exactly one task from a prior Wave, name that task's tip directly as the base — no stage commit needed.
   - **Baseline fix (`task-00`) interaction:** When Implement's baseline tests fail and the user chooses Auto-fix (see `implement/SKILL.md` → "Baseline Tests"), `task-00` is injected as a phase-level predecessor. `task-00`'s base is the feature branch tip; every other task in the phase then takes `task-00`'s tip as its base (or as one of its parents in the multi-parent case). This injection happens at runtime — Parallelize does not anticipate it. Implement persists the injection by appending a `task-00` row to the Branch Map *and* writing a `## Runtime Adjustments` section to `parallelization.md` that lists every task whose effective base changed; the original Branch Map rows are not rewritten. Readers (human or agent) reconstruct effective bases by reading the Branch Map and overlaying `## Runtime Adjustments`.
   - **Re-fork semantics (re-run, fix-round, replan):** Once a task branch exists, it is canonical for that task. Implementer-fix-round dispatches reuse the existing branch and add commits. Re-forking only happens at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset. Never re-fork an existing task branch silently — downstream task branches that descend from it would be invalidated.
   - **Reference-gate wave termination:** When a task carries `reference_gate: true` in its frontmatter (per the per-task spec contract in `skills/plan/SKILL.md`), it acts as a **wave-terminating task** — it ends its Wave, and no dependent task in any later Wave may dispatch until the reference-gated task clears. Concretely: (1) the reference-gated task occupies its own Wave (it cannot share a Wave with independent tasks, since independent tasks might otherwise dispatch in the same slot); (2) every task that depends on the reference-gated task lands in the next Wave at the earliest; (3) `parallelization.md` emits an explicit note for each reference-gated task (canonical shape: `Reference gate: task-NN ({task name}) — dependents waiting: task-XX, task-YY, task-ZZ`). If a plan contains a reference-gated task, Parallelize applies this rule automatically — it is not an operator override. A reference-gated task that has no dependents still terminates its Wave (it may not run in parallel with other tasks in its Wave), but the "dependents waiting" list is empty.

   - **Symbolic base vocabulary** (the only values allowed in the `Base` column):
     - `feature branch tip` — the tip of `qrspi/{slug}/main` at runtime
     - `task-NN tip` — the tip of `qrspi/{slug}/task-NN` (for single-parent forks across Waves, or sequential-chain predecessors)
     - `stage-after-W{N}` — the stage commit Implement creates by merging Wave N's leaves before forking the next Wave (single stage per Wave)
     - `stage-after-W{N}{suffix}` — when a Wave emits multiple stage commits (e.g., partial-merge checkpoints before different downstream Waves), each stage is distinguished by a single lowercase letter suffix: `a`, `b`, `c`, … The suffix alphabet is ordered (`a` first, then `b`, etc.) and scoped to the originating Wave index `{N}`. For example, Wave 2 with two downstream dependency groups produces `stage-after-W2a` and `stage-after-W2b`. The unsuffixed form `stage-after-W{N}` is the canonical choice when a Wave produces only one stage commit; the suffix is added only when multiple stages from the same Wave are required.
     - `task-00 tip` — the tip of the baseline-fix branch (only after Implement injects `task-00`)
   - Branch naming (informational — Implement creates the branches): `qrspi/{slug}/task-NN`; stage branches `qrspi/{slug}/stage-after-W{N}` and, when multiple stages per Wave are needed, `qrspi/{slug}/stage-after-W{N}{suffix}` (e.g., `qrspi/{slug}/stage-after-W2a`, `qrspi/{slug}/stage-after-W2b`).
3. **Merge target:** Integrate merges all task branches into the feature branch **once at phase end**, not per-task. The feature branch only changes via Integrate. (See `integrate/SKILL.md` → "Merge Strategy" for how Integrate handles dependency-ordered merges and stage-commit dedup.)
4. **PR target:** Test creates the PR from the feature branch to the base branch.

> **Why the base-naming rule matters.** A common misread is *"all task branches always fork from the feature branch."* That works for parallel-only phases but breaks sequential dependencies — task-N's worktree would start without task-(N-1)'s code. The correct rule is base-from-feature-tip for Wave 1 parallel members, base-from-previous-tip for sequential-chain members, base-from-stage-commit when a Wave has multi-parent dependencies, base-from-task-NN-tip when a downstream task has a single prior-Wave parent, and base-from-task-00-tip after a baseline fix is injected. Parallelize records the symbolic name; Implement resolves it to a concrete commit and creates stage commits as needed.

## Multi-Actor Flow Check

!cat skills/_shared/multi-actor-flow-check.md

## Process Steps

**Compaction checkpoint: pre-fanout.** Steps 2–8 below read every current-phase task spec, synthesize the dependency graph + Waves + Branch Map, and render the Mermaid diagram into `parallelization.md`. The synthesis subagent (or inline synthesis) reads many tasks and produces large output. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Surface a todo: title `Recommend /compact (pre-fanout) — parallelize`, description `pre-fanout: dependency-graph synthesis reads every current-phase task spec; large output. User decides whether to /compact.`.

1. Identify current phase's tasks from `plan.md` phase definitions
2. For each task, list dependencies and files-touched (read each `tasks/task-NN.md` or `fixes/{type}-round-NN/*.md`)
3. Group tasks into Waves (independent + file-disjoint share a Wave; otherwise separate Waves)
4. Determine execution mode (sequential / parallel / hybrid) — pick the simplest mode the dependency graph supports
5. For each Wave, decide its symbolic base per the Branch Model. For multi-parent dependencies, name a stage commit (`stage-after-W{N}`); for single prior-Wave parents, name that task's tip; for sequential chains, name the previous task's tip.
6. Build the Wave dependency graph: Wave 1 contains all Waves whose only dependency is the feature branch tip; downstream Waves declare their prerequisite Waves. Implement's runtime rule dispatches every Wave whose dependencies are satisfied each tick — concurrency derives from the dependency graph at runtime, not from Wave numbering.
7. Write `parallelization.md` with the required sections (Dependency Analysis table, Branch Map organized into `### Wave N` sub-sections each with a Task/Branch/Base mini-table, Stage Commits table if any)
8. Render the Mermaid dependency graph into the same file (do not paste the diagram into the terminal — the user opens the file to view it)
9. Present the plan to the user for approval

### Worktree-Aware Setup Validation

Before scheduling parallel task branches, validate that the project's lint/typecheck/test configurations exclude the worktree-tree pattern QRSPI uses. The Implement skill creates per-task worktrees under `.worktrees/<project>/task-NN/`, each of which may contain its own framework build directory (e.g., `.next/` for Next.js, `dist/` for Vite, `build/` for many bundlers). Without explicit exclusions, project-level lint/test invocations walk into sibling worktrees' build outputs, producing thousands of noise findings on minified code.

Validate in this order, on the project root (not in a worktree):

1. **eslint** — config (`eslint.config.js`, `.eslintrc*`, `package.json` `eslintConfig`) ignores `.worktrees/**` AND the framework build directory (`.next/**`, `dist/**`, `build/**`).
2. **tsconfig** — `tsconfig.json` `exclude` array contains `.worktrees/**` (or equivalent). If the project uses path aliases pointed at the project root, also confirm aliases don't accidentally re-include worktree paths.
3. **vitest / jest** — test config's `exclude` (or `testPathIgnorePatterns`) contains `.worktrees/**`.
4. **framework build dir under worktrees** — verify recursive globs (e.g., `.next/**` not just `.next/`) so deep worktree subtrees are covered.

**This validation is advisory, not blocking.** A missing exclusion does not halt parallelization. Surface findings as remediation suggestions in the parallelize artifact (`parallelization.md`) and as a notification line for the human reviewer:

> Worktree-aware setup validation: missing `.worktrees/**` exclusion in `eslint.config.js`. Recommended patch: add `'.worktrees/**'` to the `ignores:` array. (The worktree-noise problem manifests as inflated lint-error counts during integrate; it does not affect correctness of the per-task gates.)

The implementer running parallelize does NOT auto-apply patches. Patches are advisory-only at this gate.

## Artifact

!cat skills/_shared/evergreen-output-rule.md

`parallelization.md` — written with `status: draft` in YAML frontmatter. Required sections:

- **Execution Mode** — sequential / parallel / hybrid with one-sentence rationale
- **Dependency Analysis** — table with columns: Task / Dependencies / Files / Wave
- **Branch Map** — organized as `### Wave N` sub-section headings (one per Wave: `### Wave 1`, `### Wave 2`, …). Each sub-section contains a Task / Branch / Base mini-table restricted to the tasks belonging to that Wave. The sub-section grouping replaces both the older flat three-column Branch Map table and the standalone Execution Order narrative — the Wave ordering is read directly from the `### Wave N` headings, and intra-Wave concurrency is implicit (all rows under one heading share that Wave's dispatch). The `Base` column uses *only* the symbolic vocabulary defined in the Branch Model (`feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip`). Do not embed concrete commit hashes — Implement resolves these at runtime.
- **Stage Commits** — table (only present when any Wave has multi-parent dependencies) with columns: Stage branch / Composition / Created before
- **Mermaid dependency graph** — written inline in the file

**Reference-gate notes (when applicable).** When any task in the phase carries `reference_gate: true`, `parallelization.md` MUST include one note per gated task immediately after the Branch Map table, using this canonical shape:

```
Reference gate: task-NN ({task name}) — dependents waiting: task-XX, task-YY, task-ZZ
```

Each note appears on its own line. The dependent task IDs list every task in the phase whose dependency chain passes through the gated task. When the gated task has no dependents, the field is `— dependents waiting: (none)`. Reviewers and downstream consumers (Implement) locate gates by scanning for lines matching `Reference gate: task-` — the prefix is the canonical detection pattern.

`review_depth` and `review_mode` are runtime concerns and live in `config.md` (written by Implement at phase start), not in `parallelization.md`.

## Human Gate

Write the Mermaid dependency graph into `parallelization.md` — do not paste the diagram into the terminal. Tell the user: "Parallelization plan written to `parallelization.md` — open it to view the dependency graph."

In the terminal, present the branch map and execution mode as plain text, e.g.:

```
Execution mode: Hybrid

Branch map (symbolic — Implement resolves at runtime):
  task-01  →  qrspi/{slug}/task-01   base: feature branch tip
  task-02  →  qrspi/{slug}/task-02   base: feature branch tip
  task-03  →  qrspi/{slug}/task-03   base: stage-after-W1

Wave 1: task-01, task-02 (no file overlap; base = feature branch tip)
Wave 2: task-03 (depends on task-01 + task-02 → stage-after-W1)
```

On approval, write `status: approved` in frontmatter and commit (artifact + review file).

On rejection, write the user's feedback to `feedback/parallelize-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), revise the plan, and re-present.

## Review Round

**Compaction checkpoint: pre-fanout.** Reviewer fan-out (quality + scope, plus Codex parallels when enabled) reads `parallelization.md` plus referenced inputs after the dependency-graph synthesis + Mermaid render; each reviewer may produce >10K tokens of findings output. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Surface a todo: title `Recommend /compact (pre-fanout) — parallelize`, description `pre-fanout: quality + scope reviewer fan-out after dependency-graph synthesis. User decides whether to /compact.`.

After writing `parallelization.md` (and after every revision), run one review round per the standard QRSPI review-round flow (see `using-qrspi/SKILL.md` → "Review Round Flow"). Two parallel reviewer dispatches per artifact per round (quality + scope) — same artifact, complementary lenses, all emitting 5-field findings (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`).

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step parallelize --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/parallelize/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. For round 01 pass `--base-ref <base-branch>`; on round >= 2 review-prep auto-narrows by reading `reviews/parallelize/round-$((ROUND-1))-commit.txt` (named diagnostics `anchor-file-missing:` / `sha-format-invalid:` halt before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

The round's reviewers dispatch through the universal dispatch chain (`scripts/dispatch-agent.sh` → subagent fan-out → `scripts/await-round.sh`). Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include the `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; otherwise list only the `*-claude` tags.

```sh
REVIEW_STEP="parallelize"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/parallelize/round-${ROUND}/"
REVIEW_ARTIFACT="parallelization.md"
REVIEW_AGENTS="quality-claude=qrspi-parallelize-reviewer,scope-claude=qrspi-parallelize-scope-reviewer,quality-codex=qrspi-parallelize-reviewer,scope-codex=qrspi-parallelize-scope-reviewer"
```

!cat skills/_shared/reviewer-dispatch-prose.md

Apply fixes; loop until clean (default) or present at user request. Findings tagged `change_type: scope` or `change_type: intent` (per the change-type classifier in `skills/reviewer-protocol/SKILL.md` and the secondary-escalation rule that escalates `feedback/*.md`-citing findings to `intent`) pause the loop for explicit user resolution via the batch pause UI; `style` / `clarity` / `correctness` findings auto-apply.
4. Apply fixes; loop until clean (default) or present at user request. Findings tagged `change_type: scope` or `change_type: intent` (per the change-type classifier in `skills/reviewer-protocol/SKILL.md` and the secondary-escalation rule that escalates `feedback/*.md`-citing findings to `intent`) pause the loop for explicit user resolution via the batch pause UI; `style` / `clarity` / `correctness` findings auto-apply.

## Terminal State

**Compaction checkpoint: pre-handoff.** Parallelization plan approved; the next skill (typically Implement) will create worktrees, run baseline tests, and dispatch implementer + reviewer subagents per task — a new high-context phase that should start fresh. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Surface a todo: title `Recommend /compact (pre-handoff) — parallelize`, description `pre-handoff: Implement begins worktrees + baseline tests + per-task subagent dispatch. User decides whether to /compact.`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `parallelize` (in the standard full-pipeline route, this is `implement`).

## Task Tracking (todo list)

Granular todo items covering the user-visible Process Steps. Numbering below is local todo enumeration; each item names the Process Step it covers.

1. Read tasks and analyze dependencies (covers Process Steps 1–2)
2. Group into Waves, decide execution mode (covers Process Steps 3–4)
3. Assign symbolic bases and Wave dependency graph (covers Process Steps 5–6)
4. Write parallelization.md (covers Process Steps 7–8)
5. Run review round (Claude + Codex if enabled)
6. Present parallelization plan (covers Process Step 9)

Mark each task in_progress when starting, completed when done.

## Red Flags — STOP

- A Wave has tasks that touch overlapping files
- A `Base` column entry is something other than the four symbolic values defined in the Branch Model (no commit hashes, no improvised names)
- The Branch Map names a stage commit but no Stage Commits table exists
- A task is placed in Wave N but one of its dependencies is in Wave N or later
- `parallelization.md` is marked approved while a Wave has unresolved file overlap
- Embedding concrete commit hashes — that is Implement's job at runtime
- Including baseline-fix `task-00` in the initial Branch Map (it does not yet exist; Implement decides whether to inject it)
- Asking review depth or review mode here — those are runtime questions Implement owns
- `parallelization.md` contains a task with `reference_gate: true` but no `Reference gate: task-NN ...` note appears after the Branch Map table — the canonical note is required for every reference-gated task
- A dependent of a reference-gated task is scheduled in the same Wave as the gate — this is a wave-termination violation; the dependent MUST land in the next Wave at the earliest

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "These tasks are independent, skip the dependency analysis" | File overlap is the real risk. Analyze every time, even when the phase looks trivial. |
| "Sequential is fine, skip parallelization analysis" | Missing parallelization wastes time downstream. Analyze once, dispatch efficiently. |
| "The plan already analyzed dependencies, I can skip" | Plan dependencies are logical. Parallelize checks file-level overlap — different analysis. |
| "Single task, skip the parallelization plan" | Single-task phases still get a parallelization plan (trivial but consistent — Implement reads it as the source of truth). |
| "I'll record the actual stage commit hash so Implement doesn't have to compute it" | Stage commits don't exist yet at plan time. The symbolic name is the contract; Implement resolves it. |

## Worked Examples

Two canonical worked examples are inlined below (Good and Bad). Two additional examples — **Multi-Stage Suffix** (the `stage-after-W{N}{suffix}` grammar for disjoint downstream groups) and **Reference-Gate Wave Termination** (`reference_gate: true` plus the canonical `Reference gate:` note placement) — live at `skills/parallelize/references/worked-examples.md`.

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

**Why this fails:** missing dependency analysis (Task 3 needs 1+2 but shown parallel); no file-overlap check (Tasks 1 and 3 both modify `src/routes/auth.ts`); no execution-mode rationale; missing Branch Map `Base` column so Implement has no way to know how to fork. Note: this anti-pattern intentionally has no `### Wave N` sub-sections — the flat single-table layout is exactly the shape Parallelize replaced.


## Iron Laws — Final Reminder

The two override-critical rules for Parallelize, restated at end:

1. **NO TASK DISPATCH WITHOUT AN APPROVED PARALLELIZATION PLAN.** Parallelize produces and gates the plan; Implement consumes and enforces it. Approving a plan with unresolved file overlap inside any Wave breaks the dispatch contract.

2. **The `Base` column uses ONLY symbolic vocabulary** — `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `stage-after-W{N}{suffix}` (e.g., `stage-after-W2a`), `task-00 tip`. No concrete commit hashes, no improvised names. Implement resolves at runtime; Parallelize records only the symbolic contract.

!cat skills/_shared/behavioral-directives.md
