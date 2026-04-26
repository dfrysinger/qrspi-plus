# Per-Task Orchestrator Subagent Template

This template is the prompt framework for the **per-task orchestrator subagent** dispatched by the Implement skill (one subagent per task in the batch — see `implement/SKILL.md`). It is NOT a standalone skill and is not registered for skill discovery.

**Announce at start (subagent):** "I'm executing as a per-task orchestrator subagent — running TDD for the assigned task with correctness and thoroughness reviews, then returning to the Implement orchestrator."

## Overview

TDD execution per task in its own worktree. Write failing tests, implement to pass, run correctness and thoroughness reviews. One per-task orchestrator subagent runs per task; it dispatches an implementer subagent (`templates/implementer.md`) and reviewer subagents (`templates/correctness/*`, `templates/thoroughness/*`) and returns its terminal status to the Implement orchestrator (see `implement/SKILL.md` § Implement Is the Per-Phase Orchestration Loop).

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

## Orchestration Boundary

```
MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT
OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK.
```

Main chat's responsibilities are: dispatch subagents (implementer, reviewers, fix-rounds), aggregate their findings, gate transitions, and write review logs (`reviews/tasks/task-NN-review.md` — the only file main chat authors directly; see `## Artifact` → `### Rules` below).

Main chat does NOT: run tests / typecheck / lint, write or edit target-project source files (the `reviews/tasks/task-NN-review.md` review log is the sole exception called out above), run `git add` / `git commit`, invoke `pnpm` / `npm` / `cargo` / language toolchains, or perform "quick verification" between review rounds. Any of those activities are delegated to a fresh subagent (a new implementer dispatch, or a fix-round subagent for re-verification after fixes).

**Why this rule matters.** Subagents inherit main chat's CWD. When the Implement skill puts task work inside `{target_project}/.worktrees/{slug}/task-NN/`, a subagent dispatched from main chat picks up the worktree via a prompt-specified path, while main chat's CWD stays at project root. If main chat instead runs work directly, its CWD ends up pinned to the worktree path for the rest of the session, which triggers the pre-tool-use hook's worktree-enforcement rules (worktree containment + protected-path + L1 allowlist) on every subsequent main-chat tool call. Keeping main chat at project root preserves main chat's ability to perform hook-safe recovery actions (e.g., re-dispatching subagents, writing review logs) that would otherwise be blocked by worktree-enforcement. State files under `.qrspi/` remain hook-managed; skills never write them directly.

**Red flag — STOP.** If you find yourself about to run `pnpm` / `npm` / `cargo` / `git commit` / `Write` / `Edit` from main chat as part of task execution, stop. Dispatch a subagent instead. The only code main chat writes directly is review-log markdown under `reviews/tasks/`.

## Prompt Templates

```
implement/
├── SKILL.md                    (orchestration logic only)
└── templates/
    ├── implementer.md          (TDD execution prompt)
    ├── correctness/            (always runs — quick + deep)
    │   ├── spec-reviewer.md
    │   ├── code-quality-reviewer.md
    │   ├── silent-failure-hunter.md
    │   └── security-reviewer.md
    └── thoroughness/           (deep mode only)
        ├── goal-traceability-reviewer.md
        ├── test-coverage-reviewer.md
        ├── type-design-analyzer.md
        └── code-simplifier.md
```

Correctness checks if code is right and safe — it always runs. Thoroughness checks if it's complete, well-typed, and clean — it runs in deep mode only. Execution order: spec-reviewer first (gate), remaining correctness in parallel, then thoroughness in parallel (deep only).

## Artifact Gating

Read the task file's `pipeline` field to determine which inputs to load. The task's `pipeline` field is the single source of truth for per-task input gating — the per-task orchestrator subagent never checks `config.md` for this decision. (The Implement skill itself derives mode separately from `config.md.route` for its per-phase orchestration — see `implement/SKILL.md` § Overview.) Read `config.md` for `review_depth`, `review_mode`, and `codex_reviews` settings.

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. The per-task orchestrator subagent validates `codex_reviews`.

| Input | `pipeline: quick` | `pipeline: full` |
|-------|-------------------|-------------------|
| `task-NN.md` (full text) | Yes | Yes |
| `goals.md` with `status: approved` | Yes | Yes |
| `research/summary.md` with `status: approved` | Yes | No |
| `design.md` with `status: approved` | No | Yes |
| `structure.md` with `status: approved` | No | Yes |
| `parallelization.md` with `status: approved` | No | Yes |

<HARD-GATE>
Do NOT write production code without a failing test first.
Do NOT skip any reviewer in the configured review depth.
Do NOT proceed after BLOCKED status without changing approach.
Do NOT bypass the batch gate — every task's results are presented to the user.
</HARD-GATE>

## Per-Task TDD Process

All steps below run inside the **implementer subagent**. Main chat does not run tests, write code, or commit directly.

1. **Implementer: Read test expectations** from the task spec
2. **Implementer: Write failing tests** based on those expectations
3. **Implementer: Run tests — verify fail.** If they pass, the test is vacuous — fix it
4. **Implementer: Write minimal implementation** to make the tests pass
5. **Implementer: Run tests — verify pass.** If they fail, fix the implementation (not the test)
6. **Implementer: Sanity check and commit.** Implementer-side pass — typecheck / lint green — then commit inside the worktree's git. This is NOT the formal review; formal reviews run next as separate reviewer subagents dispatched by the orchestrator.

## Implementer Subagent Status Reporting

The implementer subagent returns one of the statuses below. The Action column names what the **orchestrator (main chat)** does next — every Action involves dispatching another subagent, never main-chat execution.

| Status | Orchestrator action |
|--------|--------|
| **DONE** | Dispatch reviewer subagents (correctness group; then thoroughness if deep) |
| **DONE_WITH_CONCERNS** | Read concerns; if correctness/scope, note in review log; dispatch reviewers |
| **NEEDS_CONTEXT** | Gather missing info, re-dispatch implementer subagent with augmented prompt |
| **BLOCKED** | Assess: re-dispatch with more context, switch to more capable model, decompose into smaller tasks, or escalate to user |

## Review Groups

| Group | Reviewer | Quick | Deep | Execution |
|-------|----------|-------|------|-----------|
| Correctness | spec-reviewer | Yes | Yes | First (gate for the rest) |
| Correctness | code-quality-reviewer | Yes | Yes | Parallel after spec passes |
| Correctness | silent-failure-hunter | Yes | Yes | Parallel after spec passes |
| Correctness | security-reviewer | Yes | Yes | Parallel after spec passes |
| Thoroughness | goal-traceability-reviewer | No | Yes | Parallel after correctness passes |
| Thoroughness | test-coverage-reviewer | No | Yes | Parallel after correctness passes |
| Thoroughness | type-design-analyzer (only when new types) | No | Yes | Parallel after correctness passes |
| Thoroughness | code-simplifier | No | Yes | Parallel after correctness passes |

## Review Fix Loop (Inner Loop, Per-Task)

All reviewer and fix work is dispatched via subagents; the orchestrator only aggregates findings and decides the next dispatch.

1. **Orchestrator: dispatch reviewer groups** (quick = correctness only, deep = correctness then thoroughness). Reviewers run as subagents in parallel within their group.
2. First pass clean → task clean.
3. Issues → **orchestrator re-dispatches reviewers** on the same code to build a complete list (up to 3 convergence rounds).
4. **Implementer-fix dispatch (with persistence):**
    - **First fix cycle:** Orchestrator dispatches an implementer-fix subagent via fresh `Agent` call with the consolidated issue list → fix subagent writes the fixes → orchestrator re-dispatches reviewers on fixed code. Capture and retain the implementer-fix subagent's agent ID.
    - **Subsequent fix cycles:** Orchestrator uses `SendMessage` to continue the SAME implementer-fix subagent (using the retained agent ID) with the new issue list, preserving its context across cycles. Why: by cycle 2, the implementer has full context of what was tried, what reviewers flagged, and which fixes worked or didn't — re-dispatching loses that. Reviewers stay re-dispatched fresh each round (they don't need cross-cycle continuity; the convergence loop already handles their stochasticity).
    - **BLOCKED escape hatch:** If the persisted implementer-fix subagent reports BLOCKED (per the status table above), the orchestrator's escalation actions require a fresh `Agent` dispatch: model switch (model is fixed at spawn time and cannot change via `SendMessage`), or task decomposition (an intentional clean-context reset to escape the stuck approach — `SendMessage` could redirect the same agent with a new scope, but the point of the escape is fresh context, not just new instructions). The escape explicitly breaks persistence.
5. Up to 3 fix cycles. If unresolved after 3, flag and move on.
6. **Single round mode:** skip convergence, dispatch once (fresh `Agent` for the first fix), re-dispatch reviewers once, flag if still issues. (Persistence is only meaningful when there are multiple fix cycles, so single-round mode never uses `SendMessage`.)

**Main chat never runs reviewers, verifiers, or fixers itself** — each round is a subagent dispatch.

## Dispatching Reviewers

- Read template from `implement/templates/{group}/{reviewer}.md`
- Launch as Claude subagent with template as prompt framework
- Provide: task spec, code changes (files + content), test results, additional context per template
- Each returns: `✅ Approved` or `❌ Issues: [file:line references]`
- **If `codex_reviews: true`:** for every Claude reviewer dispatched, dispatch `codex:rescue` in parallel with the same template + the same task/code/context. Codex returns its own findings, attributed under a `#### Codex` subsection in the review log (see Codex Subsections below). Both Claude and Codex findings feed the convergence and fix loops — neither is privileged.

## Artifact

`reviews/tasks/task-NN-review.md` — per-task review results.

### File Path

`reviews/tasks/task-NN-review.md` where `NN` is the zero-padded task number (e.g., `task-03-review.md`, `task-15-review.md`).

### Format

```markdown
---
task: NN
---

# Task NN Review

## Round 1 — Correctness

### spec-reviewer

**Model:** {actual model identifier, e.g., claude-opus-4-5}
**Prompt:**
{verbatim prompt sent to this reviewer}

**Response:**
{verbatim response received from this reviewer}

### {next reviewer}
{repeat the spec-reviewer block format for each correctness reviewer:
code-quality-reviewer, silent-failure-hunter, security-reviewer}

## Round 1 — Thoroughness (deep only)

### goal-traceability-reviewer
{same block format — repeat for: test-coverage-reviewer, type-design-analyzer, code-simplifier}

## Post-review fixes (round 1)
- {what was changed and why}

## Round 2 — Correctness
{repeat reviewer sections as above}

## Round 2 — Thoroughness (deep only)
{repeat reviewer sections as above}

## Post-review fixes (round 2)
- {what was changed and why}
```

### Skipped Reviewers

When a reviewer is skipped (e.g., `type-design-analyzer` when no new types are introduced), include the section with:

```markdown
### type-design-analyzer

**Model:** skipped
**Response:** {why this reviewer was skipped, e.g., "No new types introduced in this task"}
```

### Codex Subsections

When Codex is enabled, each reviewer section includes a `#### Codex` subsection after the Response:

```markdown
### spec-reviewer

**Model:** {actual model identifier}
**Prompt:**
{verbatim prompt}

**Response:**
{verbatim response}

#### Codex

**Model:** {codex model identifier}
**Prompt:**
{verbatim codex prompt}

**Response:**
{verbatim codex response}
```

### Rules

- The **orchestrating skill** (Implement) writes this file — not the reviewer subagents
- **Prompt and Response fields are verbatim** — no summarization, no paraphrasing
- **Model identifiers are actual** — use the real model ID (e.g., `claude-opus-4-5`), not generic names
- The `task` frontmatter field is **required** and must match the task number (numeric, no padding)
- Post-review fixes sections appear **between rounds**, listing what changed and why
- Correctness reviewers: `spec-reviewer`, `code-quality-reviewer`, `silent-failure-hunter`, `security-reviewer`
- Thoroughness reviewers (deep only): `goal-traceability-reviewer`, `test-coverage-reviewer`, `type-design-analyzer`, `code-simplifier`

## Terminal State

The per-task orchestrator subagent returns its terminal status to the Implement orchestrator (the caller). It does NOT invoke any route step, present a batch gate, or recommend compaction — those are owned by Implement (see `implement/SKILL.md` § Batch Gate, § Terminal State). Terminal statuses are: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED, or unresolved-after-3-fix-cycles.

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Mechanical tasks (1-2 files, clear spec) | Fast/cheap model (haiku) |
| Integration tasks (multi-file, pattern matching) | Standard model (sonnet) |
| Architecture/design/review | Most capable model (opus) |

## Task Tracking (TodoWrite)

Track sub-tasks per task with TodoWrite, mirroring the Per-Task TDD Process steps plus the reviewer dispatch sequence.

## Red Flags — STOP

- Writing production code before a failing test exists
- Skipping a reviewer because "the change is small"
- Proceeding after BLOCKED status without changing approach
- Fixing reviewer findings without re-running the reviewer
- Implementer self-review replacing actual reviewer-subagent dispatch
- Committing without running tests
- Accepting "close enough" on spec compliance
- 3+ attempts to pass the same test without changing approach
- Fixing a failing test by weakening the assertion
- **Main chat running tests, typecheck, lint, git commit, or file writes directly — these must be subagent work (see Orchestration Boundary)**
- **Main chat "quickly verifying" between review rounds — dispatch a fix-round or fresh verify subagent instead**

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "Too simple to test" | Simple code breaks. Write the test. |
| "I'll test after implementing" | Tests written after pass immediately — they prove nothing |
| "The test is obvious, skip verify-fail" | If you didn't see it fail, you don't know it can fail |
| "I need to write the implementation to know what to test" | Read the task spec's test expectations |
| "Mocking makes this easier" | Mock boundaries, not internals. Test real behavior. |
| "This refactor doesn't change behavior, skip tests" | If behavior doesn't change, existing tests still pass. Run them. |
| "This reviewer is redundant, I can skip it" | Each reviewer catches different classes of issues. Run them all. |
| "The change is too small for 8 reviewers" | Review depth is configured per phase, not per change. Follow config. |
| "Just this once in main chat — it's faster" | Main chat is not the worker. Dispatch a subagent. Running work in main chat pins its CWD to the worktree and triggers the pre-tool-use hook's worktree-enforcement on every subsequent tool call — including any repair writes main chat would need to make. |
| "I'll run a quick sanity check before the reviewers" | That's what the implementer subagent's sanity-check-and-commit step already did. Dispatch reviewers next. |

## Worked Example — Good TDD Cycle

**RED:**

```typescript
test('returns 429 when client exceeds 100 requests/minute', async () => {
  for (let i = 0; i < 100; i++) {
    await request(app).get('/api/data').set('X-API-Key', 'client-1');
  }
  const response = await request(app).get('/api/data').set('X-API-Key', 'client-1');
  expect(response.status).toBe(429);
  expect(response.headers['retry-after']).toBeDefined();
});
```

**Verify RED:** `FAIL: expected 429, received 200` — fails because rate limiter doesn't exist yet ✓

**GREEN:**

```typescript
export function rateLimiter(req, res, next) {
  const key = req.headers['x-api-key'] || req.ip;
  const count = increment(key);
  if (count > 100) {
    const retryAfter = Math.ceil((windowEnd(key) - Date.now()) / 1000);
    res.set('Retry-After', String(retryAfter));
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }
  next();
}
```

**Verify GREEN:** `PASS (all tests)`

**Status report:**

```
Status: DONE
Implemented: Rate limit middleware with Redis-backed counter
Tests: 6/6 passing
Files: src/middleware/rate-limiter.ts (create), src/app.ts (modify)
Self-review: Clean
```

## Worked Example — Bad (Anti-Pattern)

```
1. Wrote rate limiter middleware
2. Wrote tests to verify it works
3. All tests pass on first run ✓
```

**Why this fails:**

- Implementation before tests — violates the iron law
- Tests "pass on first run" — prove nothing
- Testing what was built, not what should be built
- Tests biased by implementation, not by task spec's test expectations

## Iron Laws — Final Reminder

The two override-critical rules for Implement, restated at end:

1. **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.** If the test passed on first run, it is vacuous — fix the test, then implement. Implementation-before-test is the most common silent quality failure.

2. **MAIN CHAT ONLY ORCHESTRATES.** All code execution, file changes, and git operations are delegated to subagents. The only file main chat authors directly is `reviews/tasks/task-NN-review.md`. If you find yourself about to run `pnpm` / `npm` / `cargo` / `git commit` / `Write` / `Edit` / `pytest` / typecheck / lint from main chat — stop and dispatch a subagent. Main-chat execution pins CWD to the worktree and triggers worktree-enforcement on every subsequent main-chat tool call.

Behavioral directives D1-D3 (encourage reviews after changes, no shortcuts for speed, no time-pressure skips) apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
