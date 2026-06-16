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

This is the locked rule set the scope-reviewer dispatch consumes (Read by the `qrspi-parallelize-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift findings dispatch off the DEFERS list; scope-compliance dispatches off the OWNS list.

### Parallelize OWNS

- The dependency graph between current-phase tasks (logical task-to-task dependencies recorded in the Dependency Analysis table).
- File-overlap analysis across tasks (the file-disjointness check that distinguishes Waves from collisions inside a Wave).
- Wave membership and Wave bases, the Wave dependency graph, the symbolic Branch Map, and the Stage Commits table when multi-parent dependencies require stage commits.
- The Mermaid dependency graph rendered into `parallelization.md`.
- The Execution Mode decision (sequential / parallel / hybrid) with one-sentence rationale.
- **Worktree-Aware Setup Validation (advisory surface only):** Parallelize surfaces remediation guidance when task file paths, branch-naming patterns, or worktree conventions indicate a setup prerequisite that Implement must satisfy before the first Wave can begin. Parallelize documents the finding in `parallelization.md` so Implement can act on it. Parallelize does NOT auto-patch `parallelization.md` or perform the setup itself — actual worktree creation, branch creation, baseline-test execution, and on-disk config edits remain with Implement (see DEFERS below).

### Parallelize DEFERS

- Task specs themselves (acceptance tests, dependencies-list, LOC estimate, description) — owned by Plan (`plan.md` + `tasks/*.md`). Parallelize consumes these as inputs and MUST NOT rewrite them.
- Per-task implementation logic (how a task achieves its goal; the actual code, test assertions, file edits) — owned by Implement (per-task TDD + review flow — see `implement/SKILL.md` § Per-Task Execution).
- Architecture decisions and trade-offs (which approach the project takes; why a slice exists) — owned by Design.
- Phasing decisions, vertical slices, Iron Law 1 rationale, the Phase 1 PoC guideline, roadmap maintenance — owned by Phasing.
- Concrete commit hashes, branch creation, worktree creation, baseline tests, runtime-injected `task-00` — owned by Implement at runtime; Parallelize records only symbolic bases.
- `review_depth` / `review_mode` / other runtime-only review configuration — owned by Implement (written into `config.md` at phase start).
- Worktree creation, branch creation, baseline-test execution, and on-disk `config.md` edits — owned by Implement even when Parallelize surfaces a Worktree-Aware Setup Validation finding. Parallelize's responsibility ends at surfacing the remediation guidance; Implement performs the work.

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

   **Why `/main`, not bare `qrspi/{slug}`** (F-14): git stores refs hierarchically and cannot have both a leaf ref `qrspi/{slug}` and a namespace `qrspi/{slug}/...` simultaneously. Naming the feature branch `qrspi/{slug}/main` makes it a sibling of the task branches under the `qrspi/{slug}/` namespace — all four kinds of branches (feature `main`, `task-NN`, `task-NNa`, `stage-after-W{N}`) coexist as namespace siblings. Bare `qrspi/{slug}` would deadlock the very first task-branch creation with `fatal: cannot lock ref ... 'refs/heads/qrspi/{slug}' exists`.
2. **Task branches — base depends on execution mode:**
   - **Wave:** A set of tasks that share a base AND have no file overlap. Wave numbering does not imply dispatch ordering — Implement's runtime rule is "dispatch every Wave whose dependencies are satisfied each tick."
   - **Parallel:** Every task in the Wave shares the Wave's *base tip* (see Hybrid below for Waves beyond Wave 1; Wave 1's base is the feature branch tip). Tasks in a Wave are independent by construction (no file overlap, no logical dependency).
   - **Sequential chain:** Task-N's base is task-(N-1)'s tip — *not* the feature branch. This is required because sequential dependencies mean task-N imports types/factories/actions/migrations introduced by task-(N-1), and the feature branch does not yet contain task-(N-1)'s work (Integrate runs once at phase end, not per-task).
   - **Hybrid (multi-parent):** When a downstream task or Wave depends on more than one task from a prior Wave, the symbolic base is `stage-after-W{N}`. Implement creates the intermediate stage commit `qrspi/{slug}/stage-after-W{N}` by merging the prior Wave's tips into a temporary branch; the next Wave then forks from that commit. Stage branches are scratch infrastructure created by Implement; their lifecycle end (merge semantics + cleanup) is Integrate's concern — see `integrate/SKILL.md` → `Merge Strategy`.
   - **Single-parent across Waves:** When a downstream task depends on exactly one task from a prior Wave, name that task's tip directly as the base — no stage commit needed.
   - **Baseline fix (`task-00`) interaction:** When Implement's baseline tests fail and the user chooses Auto-fix (see `implement/SKILL.md` → "Baseline Tests"), `task-00` is injected as a phase-level predecessor. `task-00`'s base is the feature branch tip; every other task in the phase then takes `task-00`'s tip as its base (or as one of its parents in the multi-parent case). This injection happens at runtime — Parallelize does not anticipate it. Implement persists the injection by appending a `task-00` row to the Branch Map *and* writing a `## Runtime Adjustments` section to `parallelization.md` that lists every task whose effective base changed; the original Branch Map rows are not rewritten. Readers (human or agent) reconstruct effective bases by reading the Branch Map and overlaying `## Runtime Adjustments`.
   - **Re-fork semantics (re-run, fix-round, replan):** Once a task branch exists, it is canonical for that task. Implementer-fix-round dispatches reuse the existing branch and add commits. Re-forking only happens at fresh worktree creation: a new task in a new phase, a replan-introduced task, or an explicit user-requested reset. Never re-fork an existing task branch silently — downstream task branches that descend from it would be invalidated.
   - **Reference-gate wave termination:** When a task carries `reference_gate: true` in its frontmatter (introduced by T24's per-task spec contract), it acts as a **wave-terminating task** — it ends its Wave, and no dependent task in any later Wave may dispatch until the reference-gated task clears. Concretely: (1) the reference-gated task occupies its own Wave (it cannot share a Wave with independent tasks, since independent tasks might otherwise dispatch in the same slot); (2) every task that depends on the reference-gated task lands in the next Wave at the earliest; (3) `parallelization.md` emits an explicit note for each reference-gated task (canonical shape: `Reference gate: task-NN ({task name}) — dependents waiting: task-XX, task-YY, task-ZZ`). If a plan contains a reference-gated task, Parallelize applies this rule automatically — it is not an operator override. A reference-gated task that has no dependents still terminates its Wave (it may not run in parallel with other tasks in its Wave), but the "dependents waiting" list is empty.

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

## Multi-Actor Flow Check

Before authoring any deliverable that operationalizes a design decision involving two or more actors — where "actor" means anything that performs an operation and hands off to another: scripts, subagents, orchestrators, tools, services, protocol participants, object-call participants, workflow steps, queue producers/consumers, function callers/callees — verify that the design specifies all six choreography elements:

1. **Actor inventory** — every participant named, with its role.
2. **Sequence of operations** — ordered list of who-does-what; parallelism boundaries explicit.
3. **Per-step inputs and outputs** — what each actor receives and produces at each step; where outputs are written (stdout, file path, return value, manifest entry, message).
4. **Consumer identification** — for every output, who reads it next. Outputs with no named consumer must be removed or the consumer surfaced.
5. **Loud-failure paths** — what happens when each step fails; where the failure surfaces; which actor catches it. Silent fallback is never the answer.
6. **Context-cost call-out** — for any flow that crosses a context boundary (orchestrator/subagent, process, network), explicitly state what crosses vs. what stays on disk or in the other context.

If any element is missing for an in-scope decision, **STOP** authoring against this decision and surface a concrete diagnostic to the user. Do NOT guess the missing hand-off and continue.

Diagnostic template:

> Design decision **X** enumerates actors **A, B, C** but does not specify **[missing element — e.g., "what happens if B produces no output", "how A invokes B", "who reads C's output"]**.
>
> Stopping before guessing.
>
> Recommended path: trigger the **Backward Loops** procedure (see `using-qrspi/SKILL.md` § Backward Loops) to re-open Design via its per-decision dialogue, lock the missing element, re-review + re-approve `design.md`, then cascade forward — every dependent artifact from Design onward (Phasing if phase boundaries are affected, Structure, Plan, Parallelize if task dependencies are affected) re-runs against the updated design.
>
> Alternative: provide explicit guidance to accept the gap with a documented assumption recorded against this decision in the deliverable. The assumption becomes the de-facto contract — name what you are choosing for the missing element.

**Iron law:** silently inventing a missing hand-off is a contract violation that ships half-finished features which only surface at Test or in production. Guessing-instead-of-stopping is a process failure and must be reported even if the deliverable otherwise looks complete.

## Process Steps

**Compaction checkpoint: pre-fanout.** Steps 2–8 below read every current-phase task spec, synthesize the dependency graph + Waves + Branch Map, and render the Mermaid diagram into `parallelization.md`. The synthesis subagent (or inline synthesis) reads many tasks and produces large output. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — parallelize", description: "pre-fanout: dependency-graph synthesis reads every current-phase task spec; large output. User decides whether to /compact." })`.

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

## Evergreen-Output Rule

Any artifact in the QRSPI run directory governed by `status: draft → approved` frontmatter promotion (goals, design, structure, phasing, plan, parallelization, roadmap, future-goals, and any future artifact adopting this lifecycle) describes the **current state** of decisions. The reader is a downstream agent or future maintainer.

*(Excludes by design: `SKILL.md` files — skills carry rule rationale legitimately; `feedback/*.md` — the designated home for dialogue exhaust; `reviews/**/*.md` — finding rationale; `config.md` — non-narrative.)*

**Litmus test (apply to every paragraph before write).** Two filters, in order:

1. Is the subject the **decision** (the thing being designed / planned / scoped)? → keep.
2. Is the subject the **document itself** — its drafts, its history, the dialogue that produced it, "us"? → cut.

A sentence that only makes sense as a delta from a prior state is **dialogue exhaust** — strip it.

**Permitted substantive content** (do NOT confuse with dialogue exhaust):

- Chosen approach and its rationale (inline)
- Rejected alternatives and tradeoffs, where the artifact template asks for them (e.g., design.md's `## Trade-offs Considered` — substantive content about the decision space, not about the document's history)
- Rationale embedded inline as one parenthetical when a downstream reader needs it

**Named antagonist patterns — strip on sight, substitute as shown:**

| Antagonist pattern | Recognize by | Replace with |
|---|---|---|
| Session / drafting notes | "Rule X drafting note," "this collapsed from 3 to 1 because…" | Nothing — delete. If a fact matters, embed inline in the decision. |
| Version-history narration | "earlier draft said X," "previously," "originally," "pre-cleanup" | Nothing — git history holds versions. |
| Inside baseball | text addressed to "us" / "the author," meta-explanation of the document's own structure ("this section is split into A and B because…") | The decision the structure expresses — without the structural explanation. |
| Compaction-loss recovery notes | "this nuance was almost lost during…" | Nothing — if the nuance is needed, the rule itself carries it. |
| Failure-modes-prevented lists | bullets that justify why a rule exists rather than state what to do | Strengthen the rule's wording; delete the justification list. |

Decision-process history (drafts, review rounds, feedback applied, compaction recovery) lives in feedback files, review findings, PR descriptions, and git history — never in the artifact.

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

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — parallelize", description: "pre-fanout: quality + scope reviewer fan-out after dependency-graph synthesis. User decides whether to /compact." })`.

After writing `parallelization.md` (and after every revision), run one review round per the standard QRSPI review-round flow (see `using-qrspi/SKILL.md` → "Review Round Flow"). Two parallel reviewer dispatches per artifact per round (quality + scope) — same artifact, complementary lenses, all emitting 5-field findings (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`).

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step parallelize --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/parallelize/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. When using-qrspi step 12 narrows the base ref, pass `--base-ref "$(cat reviews/parallelize/round-$((ROUND-1))-commit.txt)"` so review-prep narrows against the prior round's per-round commit SHA (using-qrspi step 12 owns the SHA-format validation and the `anchor-file-missing:`/`sha-format-invalid:` halt directions before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

The round's reviewers dispatch through the universal dispatch chain (`scripts/dispatch-agent.sh` → Task fan-out → `scripts/await-round.sh`). Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include the `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; otherwise list only the `*-claude` tags.

```sh
REVIEW_STEP="parallelize"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/parallelize/round-${ROUND}/"
REVIEW_ARTIFACT="parallelization.md"
REVIEW_AGENTS="quality-claude=qrspi-parallelize-reviewer,scope-claude=qrspi-parallelize-scope-reviewer,quality-codex=qrspi-parallelize-reviewer,scope-codex=qrspi-parallelize-scope-reviewer"
```

# Reviewer Dispatch (shared)

With `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, and `$REVIEW_AGENTS` set by the per-skill preamble above, run:

```sh
scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
  --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
  --agents "$REVIEW_AGENTS"
```

`dispatch-agent` emits M lines on stdout (one per first-party reviewer; zero lines for a third-party-only batch). Each line has the form:

```
MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

**For every emitted spec line, invoke the Task tool with these arguments (parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces):**

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim
- `model` = the `MODEL` value, verbatim
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference; the prompt argument has no other content

**Invoke all M Task tool calls in parallel in one orchestrator response** (one Task call per spec line). The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE` — do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract):** invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest (`$REVIEW_OUTPUT_DIR/.dispatch-manifest.json`) records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

**Capture each Task return value to disk before draining.** After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool, where `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself. Rationale: when a subagent cannot use the Write tool (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`; without the captured `.raw` file the fallback has nothing to work with and the round looks (incorrectly) clean.

After all Task tool calls return AND all `.raw` captures are written (Task tool is synchronous; first-party subagents with working Write tools have already written their per-finding files by this point), drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.

Apply fixes; loop until clean (default) or present at user request. Findings tagged `change_type: scope` or `change_type: intent` (per the change-type classifier in `skills/reviewer-protocol/SKILL.md` and the secondary-escalation rule that escalates `feedback/*.md`-citing findings to `intent`) pause the loop for explicit user resolution via the batch pause UI; `style` / `clarity` / `correctness` findings auto-apply.
4. Apply fixes; loop until clean (default) or present at user request. Findings tagged `change_type: scope` or `change_type: intent` (per the change-type classifier in `skills/reviewer-protocol/SKILL.md` and the secondary-escalation rule that escalates `feedback/*.md`-citing findings to `intent`) pause the loop for explicit user resolution via the batch pause UI; `style` / `clarity` / `correctness` findings auto-apply.

## Terminal State

**Compaction checkpoint: pre-handoff.** Parallelization plan approved; the next skill (typically Implement) will create worktrees, run baseline tests, and dispatch implementer + reviewer subagents per task — a new high-context phase that should start fresh. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — parallelize", description: "pre-handoff: Implement begins worktrees + baseline tests + per-task subagent dispatch. User decides whether to /compact." })`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `parallelize` (in the standard full-pipeline route, this is `implement`).

## Task Tracking (TodoWrite)

Granular TodoWrite items covering the user-visible Process Steps. Numbering below is local TodoWrite enumeration; each item names the Process Step it covers.

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

Behavioral directives D1-D4 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
