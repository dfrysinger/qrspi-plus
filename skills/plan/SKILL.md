---
name: plan
description: Use when prior artifacts are approved and the QRSPI pipeline needs detailed task specs — breaks structure into ordered tasks with test expectations, dependencies, and LOC estimates (full pipeline requires design+structure; quick fix requires only goals+research)
---

# Plan (QRSPI Step 6)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Plan skill to create detailed task specs."

## Overview

Break the structure into ordered, self-contained tasks following vertical slices and phases from the design. Each task spec includes exact file paths, descriptions, test expectations, dependencies, and LOC estimates. For large plans (6+ tasks), individual task specs are farmed out to sub-subagents.

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

For large plans, farm task spec writing to sub-subagents:

**Sub-subagent inputs:**
- `plan.md` overview
- Relevant sections of `structure.md`
- `design.md` (for test strategy and vertical slice context)

Each sub-subagent writes `tasks/task-NN.md`. After all complete, the Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files — creating a single document as the only source of truth during review.

### Plan Document Structure (During Review)

```markdown
---
status: draft
---

# Implementation Plan

## Overview
{Phase structure, task ordering, dependency graph}

## Phase 1: {name}
{Tasks in this phase, ordering rationale}

## Phase 2: {name}
{Tasks in this phase, ordering rationale}

---

## Task Specs

### Task 1: {name}
- **Phase:** 1
- **Target files:** {exact paths, create/modify}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Sizing exception:** {only present when the task is a legitimate bundle (multi-handler or >200 LOC). Reason must be one of: schema migration, CI scaffolding, reusable primitives — see Task Sizing}
- **Description:** {what this task accomplishes}
- **Test expectations:**
  - {behavior 1}
  - {edge case 1}
  - {error condition 1}

### Task 2: {name}
...
```

### Plan Reviewer Templates

Five reviewer templates run in parallel as part of the review round. All five run always — neither quick-fix nor full-pipeline mode gates any template. Templates that require `design.md` or `structure.md` emit "NOT APPLICABLE — quick-fix route" for those checks when those files are absent.

| Template | File | Focus | Run Condition |
|----------|------|-------|---------------|
| Spec Reviewer | `templates/spec-reviewer.md` | Completeness, scope, interpretation, test coverage mapping, placeholder detection | Always |
| Security Reviewer | `templates/security-reviewer.md` | Fail-closed requirements, input validation, auth/authz, no insecure defaults | Always |
| Silent Failure Hunter | `templates/silent-failure-hunter.md` | Swallowed errors, silent fallbacks, partial state on failure, log-and-continue | Always |
| Goal Traceability Reviewer | `templates/goal-traceability-reviewer.md` | Forward trace, backward trace, gap analysis, spec-to-design fidelity | Always |
| Test Coverage Reviewer | `templates/test-coverage-reviewer.md` | Behavioral coverage, edge cases, error conditions, test expectation quality, missing design scenarios | Always |

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Plan-specific reviewer instructions:

- **Claude review subagent** runs all five reviewer templates from `skills/plan/templates/` in parallel (subagent fills in artifact content, runs each template as a separate pass, returns combined findings). Inputs: `plan.md` (merged), `goals.md`, `research/summary.md`, plus `design.md` and `structure.md` (full pipeline only). Findings written to `reviews/plan-review.md`.
- **Codex review** (if `codex_reviews: true`) — `codex:rescue` with the same inputs and criteria. Findings appended to `reviews/plan-review.md`.
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

If the artifact directory is inside a git repository, commit the approved `plan.md`, all `tasks/task-NN.md` files, and `reviews/plan-review.md` (see `using-qrspi` → "Commit after approval (when applicable)").

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
