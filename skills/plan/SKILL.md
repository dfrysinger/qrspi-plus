---
name: plan
description: Use when prior artifacts are approved and the QRSPI pipeline needs detailed task specs — breaks structure into ordered tasks with test expectations, dependencies, and LOC estimates (full pipeline requires design+structure; quick fix requires only goals+research)
---

# Plan (QRSPI Step 6)

**Announce at start:** "I'm using the QRSPI Plan skill to create detailed task specs."

## Overview

Break the structure into ordered, self-contained tasks following vertical slices and phases from the design. Each task spec includes exact file paths, descriptions, test expectations, dependencies, and LOC estimates. For large plans (6+ tasks), individual task specs are farmed out to sub-subagents.

## Plan OWNS / Plan DEFERS

This section is the **single source of truth** for plan.md scope boundaries. The parameterized scope-reviewer (instantiated with `{ARTIFACT_TYPE}=plan`) parses the OWNS and DEFERS lists below as its locked rule input — boundary-drift findings, scope-compliance findings, and U14 lexical-leakage checks all run against the enumerated items here.

**Length target.** plan.md aggregate length sits in the **1000–2000 lines** soft window once all task specs are appended for review (Q29's Keeplii corpus averages ~52 lines per task spec; a 10-20-task phase lands inside this band). Per-task specs are intentionally **short** — terse bullets, no narrative preamble, no design rationale repetition. The aggregate band is a soft target, not a ceiling: reviewers should flag a plan that drifts well outside it (e.g., 200 lines for 10 tasks signals under-specification; 4000 lines signals task specs that have grown into design or implementation prose).

**INVEST Negotiable framing.** Per Q28, a plan task spec is a **conversation, not a contract**. Plan owns the scoping decisions and the test expectations; downstream skills (Structure, Implement, Implement-TDD) own the implementation choices that flow from those decisions. The DEFERS list below is the operational form of "Negotiable": the items deferred to later artifacts MUST stay out of plan.md — encoding a function signature or a line-by-line algorithm in a task spec turns the spec into a contract, forecloses Structure/Implement's negotiation room, and is grounds for a scope finding from the scope-reviewer.

### Plan OWNS

The plan.md artifact is the only authoring location for these concerns. Every paragraph or bulleted item in plan.md must trace to one of these:

- **Ordered task specs** — the per-phase ordered list of tasks, each implementing exactly one observable behavior (one request handler, one use case, one user-visible change).
- **Test expectations** in plain language per task — behaviors, inputs/outputs, edge cases, error conditions. Plain language only; not assertion code, not `expect(...)` strings.
- **Dependencies** — explicit task-to-task ordering (`Task 3 depends on Task 1, Task 2` or `Dependencies: none`). Forward dependencies are forbidden.
- **LOC estimates per task** — `~N` per task; the policy ceiling is 200 LOC and the target is ~100 LOC; see Task Sizing for the splitting protocol.

### Plan DEFERS

The following concerns are explicitly **out of plan.md scope**. Each DEFERS entry names the destination artifact that owns the concern. A finding that observes any of these in plan.md is a boundary-drift finding (`change_type: scope`); per the INVEST Negotiable framing above, the spec's job is to set the conversation, not pre-empt the downstream skill's negotiation.

- **Function signatures, type definitions, parameter shapes** → `structure.md` (interface contracts per file are Structure's OWNS, not Plan's). Conversation, not contract: Plan says "rate limiter middleware exposes a single Express handler"; Structure says `rateLimiter(req, res, next)`.
- **Full assertion text / `expect(...)` / test code** → Implement-TDD (Implement's TDD cycle authors the failing test first). Conversation, not contract: Plan says "returns 429 when client exceeds 100 requests/minute"; Implement-TDD writes `expect(res.statusCode).toBe(429)`.
- **Line-by-line logic, control-flow detail, algorithm pseudocode** → Implement (the implementation agent owns local logic decisions inside the task's bounded scope). Conversation, not contract: Plan says "increment Redis counter on each allowed request"; Implement chooses `INCR` vs. `EVAL` with a Lua script.
- **Architecture decisions, key trade-offs, system diagrams** → `design.md` (locked upstream; Plan consumes, does not re-author).
- **Phasing, vertical slice authoring, roadmap maintenance, replan-gate criteria** → `phasing.md` / Phasing skill (per M54). Plan consumes phase boundaries from Phasing; it does not re-decide them.

### Boundary-drift signals (U14 lexical leakage)

The following lexical patterns in plan.md indicate boundary drift from a later pipeline stage and trigger a U14 boundary-drift finding from the scope-reviewer:

- **Function signatures inline in a task spec** (parenthesized parameter lists, return-type arrows) — Structure-layer leak.
- **`expect(`, `assert.`, `assertEqual`, `toBe(` in a Test Expectations bullet** — Implement-TDD-layer leak.
- **`if/else`, `for`, `while`, line-numbered logic walkthroughs** — Implement-layer leak.
- **"trade-off", "we considered", "alternative approach"** in task description — Design-layer leak.
- **"phase 2 will...", "future phases", roadmap-style forward references** — Phasing-layer leak.

## Artifact Gating

Read `config.md` to determine pipeline mode. If `config.md` doesn't exist or has no `route` field, refuse to proceed and tell the user to re-run Goals to set the pipeline mode. The `route` field is authoritative; `pipeline` is informational (see using-qrspi Config File section).

**Full pipeline (`pipeline: full`) — required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `design.md` with `status: approved`
- `structure.md` with `status: approved`

**Quick fix (`pipeline: quick`) — required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`

Note: Design and Structure are not in the quick fix route, so `design.md` and `structure.md` don't exist.

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Plan validates `pipeline`, `route`, and `codex_reviews`.

<HARD-GATE>
Do NOT produce plan.md without all required artifacts approved (full: goals + research + design + structure; quick: goals + research).
Do NOT use placeholder content in task specs: no TBD, TODO, "similar to Task N", "add appropriate handling".
Every task spec must be self-contained — an implementation agent reading only that task must have everything it needs.
</HARD-GATE>

## Execution Model

**Subagent** produces `plan.md` overview. For large plans (6+ tasks), individual task specs are farmed out to sub-subagents (one per task or related group) to keep context manageable. Iterative with human feedback.

## Phase-Scoped Content Rules

plan.md contains ONLY current-phase tasks. Each task must reference a goal ID that exists in goals.md. Tasks for goals not in the current phase must not appear. The `goal_id` field in task frontmatter must match a goal in goals.md.

## Task Sizing

Each task implements **exactly one observable behavior** — one request handler, one use case, one user-visible change. The task title names exactly one feature, with no `+` joining feature names and no two distinct verbs joined by `and`.

**LOC budget per task:**
- Target: ~100 LOC (matches OpenAI AGENTS.md guidance for autonomous-agent task scope)
- Policy ceiling: 200 LOC — split unless a `sizing_exception` (post-split frontmatter) or **Sizing exception** bullet (in-plan) names one of: schema migration, CI scaffolding, reusable primitives

**Why:** SWE-Bench Pro reports a median patch size of 107 LOC / 4.1 files, with frontier-model success around 23% at that size (GPT-5, Opus 4.1). OpenAI's AGENTS.md guidance targets ~100 lines per agentic task. Our 100-LOC target matches that guidance; the 200-LOC ceiling sits at the lower bound of Cisco/SmartBear's code-review sweet spot (200-400 LOC) and gives margin for QRSPI's enhanced scaffolding (fresh-context subagents, structured task specs, TDD cycle, multi-reviewer loop). Multi-feature task titles like `auth + allowlist + rename + admin` are the visible symptom of oversized tasks; the underlying cause is bundling N request handlers into one task, which re-couples slices that vertical-slice decomposition exists to separate.

**Splitting protocol.** A task estimated >200 LOC splits into N tasks at or below the ~100-LOC target, each implementing one handler with explicit dependency ordering. The closed exception set is: schema migration, CI scaffolding, reusable primitives. Mark `sizing_exception: <reason>` in the task frontmatter (post-split) or the **Sizing exception** bullet inside the in-plan task spec (pre-split), and explain in the Description.

**Floor — a task is too small if any of these hold:**
- Does not traverse the layers needed for its behavior (UI-only, schema-only, mock-only, test-only)
- Produces no observable behavior change when merged alone (pure refactor with no callers, scaffold with no consumer)
- Depends on a sibling task to compile or pass tests
- Cannot be merged to main alone (must batch with peers to ship)

A task that fails any floor check merges into the parent task that gives it observable behavior; do not ship sub-atomic tasks.

## Process

### Plan Overview Subagent

**Inputs:**
- `goals.md`
- `research/summary.md`
- `design.md`
- `structure.md`
- Any prior feedback files

**Task:** Break the structure into ordered tasks following vertical slices and phases.

1. Break structure into ordered tasks following vertical slices and phases from `design.md`
2. Each task spec includes:
   - Exact file paths to create/modify
   - Description of what the task accomplishes
   - Test expectations in plain language (behaviors, inputs/outputs, edge cases, error conditions)
   - Dependencies on other tasks
   - LOC estimate
3. No placeholders, no TBDs, no "similar to Task N" — each spec is self-contained

**For small plans (<6 tasks):** The overview subagent writes the full merged `plan.md` directly (overview + task specs in one document).

**For large plans (6+ tasks):** The overview subagent writes `plan.md` with only the overview section (phase structure, task ordering, dependency graph). Individual task specs are dispatched to sub-subagents.

### Quick-Fix Plan Behavior

When `config.md` has `pipeline: quick`:

1. The plan subagent receives `goals.md` and `research/summary.md` only (no design.md or structure.md)
2. Produces a **single-task plan** directly — no sub-subagent dispatch, no merge/split lifecycle
3. The task spec derives file paths and test expectations from the research findings and goals
4. The merged `plan.md` contains both the overview and the single task spec
5. After approval, the single task is written to `tasks/task-01.md` and `plan.md` is reduced to overview-only (same mechanics as full pipeline, but always exactly one task)

The review round, human gate, and approval process are identical to full pipeline mode.

### Sub-Subagent Dispatch (Large Plans Only)

> **IMPORTANT — Compaction recommended.** The per-task spec-generation sub-subagent dispatch fans out to one subagent per task (or related group) and each writes a self-contained `tasks/task-NN.md`. Aggregate sub-subagent output is large and the orchestrator must hold all returned task files plus the merged plan.md in context for the upcoming review round. Run `/compact` before dispatching if context utilization may exceed ~50%. **Iron Rule:** do NOT dispatch the per-task spec-generation fan-out without first checking utilization at this site — losing earlier conversation history mid-merge corrupts the single-source-of-truth invariant.

For large plans, farm task spec writing to sub-subagents:

**Sub-subagent inputs:**
- `plan.md` overview
- Relevant sections of `structure.md`
- `design.md` (for test strategy and vertical slice context)

Each sub-subagent writes `tasks/task-NN.md`. After all complete, the Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files — creating a single document as the only source of truth during review.

### Plan Document Structure (During Review)

The output template below embeds **U14 information-mapping patterns** directly: claim-before-evidence (the task title and Description's first sentence carry the load-bearing claim — what observable behavior the task delivers); one-paragraph-per-claim density (each bullet carries one claim, no compound bullets); scannable bullets and required headings (Phase / Target files / Dependencies / LOC estimate / Description / Test expectations are required structural slots, not optional prose); no "be concise" instructions (per Q1 Phare benchmark and Q2 Hakim — research-backed; brevity directives degrade factual reliability). Per-task specs are short by structural design (terse bullets, no narrative), not by an explicit brevity instruction.

```markdown
---
status: draft
---

# Implementation Plan

## Overview
{Phase structure, task ordering, dependency graph — claim first, then supporting structure}

## Phase 1: {name}
{Tasks in this phase, ordering rationale — one paragraph per claim, scannable bullets}

## Phase 2: {name}
{Tasks in this phase, ordering rationale}

---

## Task Specs

### Task 1: {name — names exactly one observable behavior; no `+` joining feature names; no two distinct verbs joined by `and`}
- **Phase:** 1
- **Target files:** {exact paths, create/modify}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Sizing exception:** {only present when the task is a legitimate bundle (multi-handler or >200 LOC). Reason must be one of: schema migration, CI scaffolding, reusable primitives — see Task Sizing}
- **Description:** {what this task accomplishes — claim-before-evidence: lead with the observable-behavior sentence, then supporting context. Plain language; no function signatures (→ Structure); no algorithm pseudocode (→ Implement); no architecture rationale (→ Design).}
- **Test expectations:**
  - {behavior 1 — plain language; no `expect(...)` or assertion code (→ Implement-TDD)}
  - {edge case 1}
  - {error condition 1}

### Task 2: {name}
...
```

**U14 conformance reminder for the per-task spec writer.** Each task spec must satisfy: required-section presence (every bullet header above is required); claim-line length ≤ 250 chars per bullet; description paragraph ≤ 150 words; section ≤ 300 words total before bullets are split; no brevity directives anywhere ("be concise", "brief summary", "≤ N lines" are forbidden — see U14 lint allowlist for the legitimate length-target exceptions). The DEFERS list above tells the writer what NOT to put in the spec; this conformance reminder tells the writer how to structure what they DO put in.

### Plan Reviewer Templates

Six reviewer templates run in parallel as part of the review round. All six run always — neither quick-fix nor full-pipeline mode gates any template. Templates that require `design.md` or `structure.md` emit "NOT APPLICABLE — quick-fix route" for those checks when those files are absent.

| Template | File | Focus | Run Condition |
|----------|------|-------|---------------|
| Spec Reviewer | `templates/spec-reviewer.md` | Completeness, scope, interpretation, test coverage mapping, placeholder detection | Always |
| Security Reviewer | `templates/security-reviewer.md` | Fail-closed requirements, input validation, auth/authz, no insecure defaults | Always |
| Silent Failure Hunter | `templates/silent-failure-hunter.md` | Swallowed errors, silent fallbacks, partial state on failure, log-and-continue | Always |
| Goal Traceability Reviewer | `templates/goal-traceability-reviewer.md` | Forward trace, backward trace, gap analysis, spec-to-design fidelity | Always |
| Test Coverage Reviewer | `templates/test-coverage-reviewer.md` | Behavioral coverage, edge cases, error conditions, test expectation quality, missing design scenarios | Always |
| Scope Reviewer | `_shared/templates/scope-reviewer.md` (parameterized; `{ARTIFACT_TYPE}=plan`) | OWNS/DEFERS boundary-drift detection per `## Plan OWNS / Plan DEFERS` below; scope-compliance per locked Plan rules; U14 boundary-drift signal | Always |

### Review Round

> **IMPORTANT — Compaction recommended (pre-review-loop).** The merged `plan.md` plus `goals.md` + `research/summary.md` + `design.md` + `structure.md` are about to be handed to the review-round dispatch. Reviewer findings only land cleanly on a context that still holds the synthesis decisions; if utilization may exceed ~50%, run `/compact` now — before reviewers dispatch — so the upcoming cross-file consistency checks have headroom. **Iron Rule:** review-round dispatch is the highest-leverage compaction moment in Plan; do not skip this check.

> **IMPORTANT — Compaction recommended (pre-large-subagent-dispatch).** The Claude review subagent runs six reviewer templates in parallel (five plan-specific + the parameterized scope-reviewer with `{ARTIFACT_TYPE}=plan`) and the Codex review wrapper launches in parallel as a non-blocking job. Aggregate reviewer output is large. RED FLAG: dispatching the parallel reviewer fan-out on a near-full context produces truncated findings and missed cross-file inconsistencies — run `/compact` if utilization may exceed ~50% before launching either dispatch.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Plan-specific reviewer instructions:

- **Claude review subagent** runs all six reviewer templates in parallel (five from `skills/plan/templates/` plus the parameterized scope-reviewer from `skills/_shared/templates/scope-reviewer.md` instantiated with `{ARTIFACT_TYPE}=plan`). The subagent fills in artifact content, runs each template as a separate pass, and returns combined findings. Inputs: `plan.md` (merged), `goals.md`, `research/summary.md`, plus `design.md` and `structure.md` (full pipeline only). The reviewer-subagent prompt **embeds `skills/_shared/reviewer-boilerplate.md` verbatim** so every finding (Claude reviewer + scope-reviewer) emits the M48 five-field schema (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`) under the disagreement-valid framing. The scope-reviewer dispatch parses the `## Plan OWNS / Plan DEFERS` section below as its locked rule input — boundary-drift, scope-compliance, and U14 lexical-leakage checks all run against that section. Findings written to `reviews/plan-review.md`.
- **Codex review** (if `codex_reviews: true`) — dispatch a non-blocking Codex review via the wrapper:
  1. Write the review prompt (`plan.md` + `goals.md` + `research/summary.md` + `design.md` + `structure.md` (full pipeline only) + the same five-template criteria + the embedded `skills/_shared/reviewer-boilerplate.md` content) to a temporary file (e.g., `/tmp/codex-prompt-plan.md`).
  2. Launch the job early (in parallel with the Claude reviewer above) by running `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-plan.md` as a foreground Bash-tool call. The wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds. The orchestrator (this skill's caller — the Claude Code agent driving the Bash tool) records that printed jobId text from the Bash tool's stdout output and pastes it as the literal `<jobId>` argument in the matching await Bash call below; there is no shell variable assignment in this flow, and shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md. If launch exits non-zero, abort this Codex review and append a launch-failure note to `reviews/plan-review.md`.
  3. After the Claude reviewer returns, await the result: `scripts/codex-companion-bg.sh await <jobId>`. Exit codes: **0** = success, append the markdown stdout to `reviews/plan-review.md` under `#### Codex`; **10** = 20-min ceiling hit (no stdout produced) — append an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`), do NOT append empty stdout, do NOT silently retry; **11** = companion crash mid-job (job-not-found) — append a crash note and surface to the user before proceeding; **12** = audit-write fail (e.g., row > 4096 bytes) — append an infrastructure-failure note and surface to the user, do NOT retry blindly. **Only append stdout to the review log on exit 0.**
- The default-option-2 recommendation is especially important here because plan reviews catch cross-file consistency / forward dependencies / migration ordering across 10+ task specs that the human cannot feasibly verify by hand.

### Human Gate

Present merged `plan.md` to the user — overview for approval, task details for spot-checking. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

**On approval:**

1. **If reviews have NOT passed clean** (the user chose option 1 earlier, or backward loops introduced changes after the last clean round): Ask the user before proceeding: "Reviews haven't passed clean yet. Would you like me to run a review loop to clean before splitting? This is strongly recommended — the review cycle catches cross-file inconsistencies that are hard to spot manually." If the user agrees, run the review loop (same as option 2 above), then continue. If they decline, proceed.

2. **Recommend compaction before splitting:** "Plan approved. This is a good point to compact context (`/compact`) before I split tasks into individual files — the split is mechanical and doesn't need the full conversation history." Wait for the user to compact (or decline), then proceed.

3. **Split:** Split task sections into individual `tasks/task-NN.md` files, then reduce `plan.md` to overview-only, then write `status: approved` in `plan.md` frontmatter. This ensures `tasks/*.md` files exist before `plan.md` is marked approved, avoiding a transient state where downstream skills see an approved plan but no task files.

**On rejection:** Write the user's feedback and the rejected artifact snapshot to `feedback/plan-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then launch a new subagent with original inputs + **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts from the beginning (the "loop until clean" choice applies to the new round).

### Merge/Split Mechanics

- **Before review:** For large plans (6+ tasks), sub-subagents write `tasks/task-NN.md` files → Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files → single document is the only source of truth during review. For small plans (<6 tasks), the plan subagent writes the merged `plan.md` directly.
- **During review:** All changes happen in the single `plan.md` — `tasks/` directory is empty, no dual source of truth.
- **After approval:** Plan skill splits each `### Task N` section back into `tasks/task-NN.md` files, then reduces `plan.md` to overview-only (removing the appended task specs). No duplication.

**Split task file format** (`tasks/task-NN.md`):

```markdown
---
status: approved
task: NN
phase: {phase number}
pipeline: full
# Optional: justify a legitimate bundle (multi-handler or >200 LOC).
# Reason must be one of: schema migration, CI scaffolding, reusable primitives.
# sizing_exception: <one-line reason>
# (Per-task enforcement fields removed in 2026-04-26 implement-runtime-fix.
#  Target files are aspirational; deviation discipline lives in the per-task
#  spec reviewer, not the hook.)
---

# Task NN: {name}

- **Target files:** {exact paths, create/modify}
- **Dependencies:** {task numbers or "none"}
- **LOC estimate:** ~{N}
- **Description:** {what this task accomplishes}
- **Test expectations:**
  - {behavior 1}
  - {edge case 1}
  - {error condition 1}
```

The `pipeline` field is copied from `config.md`'s `pipeline` value at plan time. The per-task orchestrator subagent reads the task file's `pipeline` field for per-task input gating (which artifacts to load for the task's review context). The Implement skill itself derives run mode separately from `config.md.route` for its per-phase orchestration — see `implement/SKILL.md` § Overview.

**Who writes the pipeline field:**
- **Plan skill** — copies from `config.md` onto every `tasks/task-NN.md` at plan time
- **Test skill** — classifies per failure (quick or full) on fix tasks
- **Integrate skill** — always `full` on integration/CI fix tasks
- **Implement baseline fix** — inherits the run's mode (derived by Implement from `config.md.route` per `implement/SKILL.md` § Overview) on task-00 (`pipeline: full` in full-pipeline runs, `pipeline: quick` in quick-fix runs) so the per-task orchestrator's input gating matches the artifacts that exist. Implement writes the runtime-injected `task-00.md` with `status: approved` so the Iron Law gate passes on dispatch.

**Fix task files** also include a `fix_type` field (not present on regular tasks):
- `fix_type: integration` — written by Integrate for cross-task integration fixes
- `fix_type: ci` — written by Integrate for CI pipeline fix tasks
- `fix_type: test` — written by Test for acceptance test fix tasks

Fix tasks are stored in `fixes/{type}-round-NN/` and follow the same format as regular tasks so the Implement skill can process them identically.

### Artifacts

- `plan.md` — complete plan with overview + all task specs (review artifact), overview-only after approval
- `tasks/task-NN.md` — individual task specs split out after approval (implementation artifacts)

### `.qrspi/` Directory

The artifact directory contains a `.qrspi/` subdirectory managed by hooks (not by this skill):

- `state.json` — pipeline state cache (current step, approved artifacts, `phase_start_commit`)
- `task-NN-runtime.json` — per-task runtime overrides: user mid-task decisions like approved extra files and enforcement mode switches (written by hooks during implementation)
- `audit-task-NN.jsonl` — per-task audit logs (written by hooks during implementation)

**This directory is created and managed by hooks.** The Plan skill does not need to create, update, or read files in `.qrspi/`.

**State management is deterministic and hook-driven:**
- The SessionStart hook initializes and reconciles `state.json` from artifact frontmatter at the start of each session
- The PostToolUse hook syncs `state.json` automatically whenever artifact frontmatter changes (e.g., when `status: approved` is written)
- Skills do NOT need to update `state.json` when artifacts are approved — the hook handles this

**Exception — `phase_start_commit`:** The Plan skill writes `phase_start_commit` directly to `state.json` when `plan.md` is approved. This records the current HEAD hash as the diff boundary for post-integration reviews. Plan is one of three narrow exceptions to hook-driven state writes (Goals bootstrap, Plan `phase_start_commit`, Replan pre-emptive reconciliation on next-phase restart) — see `using-qrspi/SKILL.md` → "Hook-Managed State (`.qrspi/`)" for the canonical list. All other state updates are hook-driven.

### Terminal State

> **IMPORTANT — Compaction recommended (terminal state).** Plan has just split tasks into individual files and committed the approved artifacts. The conversation history from the synthesis + review rounds is no longer load-bearing for downstream skills (Parallelize, Implement, Integrate read the artifacts, not the chat). Run `/compact` here if utilization is non-trivial. **Iron Rule:** carrying Plan's full review history into Parallelize burns context the next skill needs for dependency-graph reasoning.

Commit the approved `plan.md`, all `tasks/task-NN.md` files, and `reviews/plan-review.md` to git.

> **IMPORTANT — Compaction recommended (cross-skill transition).** Before invoking the next skill in the `config.md` route, run `/compact` if utilization may exceed ~50%. The next skill (typically Parallelize) starts a fresh dependency-analysis flow; it does not need Plan's reviewer transcripts or sub-subagent dispatch traces. **Iron Rule:** the cross-skill boundary is the canonical compaction moment — do not invoke the next skill on a saturated context.

**REQUIRED:** Invoke the next skill in the `config.md` route after `plan`.

If compaction was not done before splitting (user declined), recommend it now: "This is a good point to compact context before the next step (`/compact`)."

## Red Flags — STOP

- A task spec contains "TBD", "TODO", "implement later", or "fill in details"
- A task says "similar to Task N" instead of repeating the full spec
- Test expectations say "write tests" without specifying what behaviors to test
- A task references a type, function, or file not defined in any task
- A task depends on a later task (forward dependency)
- LOC estimate is missing or wildly unrealistic (e.g., 10 LOC for a full CRUD implementation)
- LOC estimate >200 without a `sizing_exception` (post-split frontmatter) or **Sizing exception** bullet (in-plan) naming one of the closed exception set (split unless the exception is documented — see Task Sizing)
- Task title contains `+` joining feature names, or two distinct verbs joined by `and` (multi-feature bundle — split into per-handler tasks)
- Task description implies multiple request handlers / use cases (one task = one handler — see Task Sizing)
- Task fails a floor check (no observable behavior, depends on sibling to compile, cannot merge alone — see Task Sizing floor)
- A task touches files from a different vertical slice without justification
- Phase boundaries don't align with the design's phase definitions
- Quick-fix plan has more than one task (quick fix = single task by definition)

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The implementation agent will figure out the details" | No. The plan is the contract. Vague specs produce wrong implementations. |
| "This task is similar to Task N, I'll just reference it" | Each task must be self-contained. The agent may read tasks out of order. |
| "Test expectations are implied by the description" | Write them explicitly. The Test skill uses them to generate acceptance tests. |
| "LOC estimates don't matter" | They signal scope. Unrealistic estimates mean the task is misunderstood. |
| "We can split this task during implementation" | Split now. The plan is where decomposition happens, not implementation. |
| "Splitting these features adds coordination overhead" | SWE-Bench Pro reports ~23% frontier-model success at the 107-LOC median patch size; tasks above the 200-LOC ceiling sit well past that empirical cliff. Coordination overhead is cheaper than the retry cost on a sub-50% pass rate. |
| "These features all live in the same file" | File overlap is not handler overlap. One handler per task even if multiple share a file — separate tasks can sequence edits inside one file via Dependencies. |
| "Schema setup naturally bundles, this is fine" | True only for the closed exception set: schema migration, CI scaffolding, reusable primitives. Mark `sizing_exception: <reason>` (post-split frontmatter) or **Sizing exception** bullet (in-plan) and explain in the Description. Do not use as a general escape hatch. |
| "Quick fix doesn't need a plan" | Quick fix mode still produces a plan — it's just a single-task plan. The plan ensures the fix is reviewed before implementation. |

## Worked Example

**Good task spec:**

```markdown
### Task 3: Rate limit middleware

- **Phase:** 1
- **Target files:** create `src/middleware/rate-limiter.ts`, modify `src/app.ts:34-40`
- **Dependencies:** Task 1 (Redis client), Task 2 (rate limit types)
- **LOC estimate:** ~60
- **Description:** Express middleware that checks the client's request count against the rate limit using the Redis client from Task 1. If exceeded, returns 429 with Retry-After header. If under limit, increments the counter and calls next().
- **Test expectations:**
  - Returns 429 when client exceeds 100 requests/minute
  - Returns Retry-After header with seconds until window resets
  - Calls next() when client is under limit
  - Increments Redis counter on each allowed request
  - Extracts client ID from X-Forwarded-For header
  - Returns 429 (not 500) when Redis is unreachable (fail closed)
  - Handles missing X-Forwarded-For gracefully (use IP as fallback)
```

**Bad task spec (vague, placeholders):**

```markdown
### Task 3: Rate limiting

- **Target files:** TBD
- **Dependencies:** none
- **LOC estimate:** ~200
- **Description:** Add rate limiting middleware. Similar to Task 2 but for the middleware layer.
- **Test expectations:**
  - Rate limiting works correctly
  - Edge cases are handled
```

The bad example has TBD files, no dependencies (but clearly needs the Redis client), unrealistic LOC, references "similar to Task 2", and test expectations that can't be verified ("works correctly", "are handled").

## Iron Laws — Final Reminder

The four override-critical rules for Plan, restated at end:

1. **No plan.md without all required artifacts approved.** Full pipeline: goals + research + design + structure. Quick fix: goals + research. Plan refuses to run otherwise.

2. **No placeholders in task specs.** No "TBD", "TODO", "implement later", "similar to Task N", "add appropriate handling." Every task spec must be self-contained — an implementation agent reading only that task must have everything it needs.

3. **One task = one observable behavior, ~100-LOC target / ≤200 LOC ceiling.** Split before approving any task that exceeds the policy ceiling unless the task documents a `sizing_exception` (post-split frontmatter) or **Sizing exception** bullet (in-plan) naming one of the closed exception set: schema migration, CI scaffolding, reusable primitives. Multi-feature task titles (`+` joining feature names, two distinct verbs joined by `and`) are the canary — they almost always mean multiple request handlers bundled into one task. SWE-Bench Pro reports ~23% frontier-model success at the 107-LOC median patch size; OpenAI AGENTS.md guidance targets ~100 lines; our 200-LOC ceiling sits at the lower bound of Cisco/SmartBear's code-review sweet spot with margin for QRSPI's enhanced scaffolding. See "Task Sizing" earlier in this skill for full rules including the floor.

4. **`phase_start_commit` write is the only direct state.json write Plan performs.** Done when `plan.md` is approved. All other state updates are hook-driven — see `using-qrspi/SKILL.md` → "Hook-Managed State."

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
