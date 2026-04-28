---
name: test
description: Use when implementation is complete (after Integrate in full pipeline, after Implement in quick fix) — runs acceptance testing against goals, routes failures through fix pipeline, handles phase completion and PR creation
---

# Test (QRSPI Step 10)

**Announce at start:** "I'm using the QRSPI Test skill to run acceptance testing against the original goals."

## Overview

Final acceptance testing for the current phase. Verify implementation meets goals end-to-end. The test-writer subagent (clean context) writes tests and produces a coverage analysis. The orchestrating skill (main conversation) runs the tests, manages the review loop, writes fix task descriptions for failures, and handles phase routing. Fix task descriptions are written by the orchestrator based on test failure output — not by the test-writer subagent.

## Iron Law

```
NO PRODUCTION CODE FIXES IN THE TEST SKILL — ROUTE THROUGH THE PIPELINE
```

## Prompt Templates

```
test/
├── SKILL.md
└── templates/
    ├── test-writer.md
    ├── acceptance-test.md
    ├── integration-test.md
    ├── e2e-test.md
    └── boundary-test.md
```

## Artifact Gating

Required inputs:
- `goals.md` with `status: approved` (original intent)
- `design.md` with `status: approved` (full pipeline only — phase definitions and acceptance context)
- `research/summary.md` with `status: approved` (quick fix only — provides design-like context)
- `fixes/` directory contents (for regression test coverage — may be empty if no prior fixes)
- Codebase with implementation merged

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled.

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Test validates `codex_reviews`.

In quick fix mode, Test receives `goals.md` and `research/summary.md` instead of `design.md`. Phase routing is not needed (quick fix is always single-phase). Acceptance criteria come from `plan.md`'s per-task `## Test Expectations` blocks (and `plan.md`'s per-phase acceptance block, if present); `goals.md` is read for problem framing and traceability only — per T9's strip-from-goals contract, `goals.md` does NOT author acceptance criteria.

<HARD-GATE>
The tester can ONLY write test files and run test commands.
When tests fail, output fix task descriptions — NOT code fixes.
All production code changes route through the pipeline:
- Full pipeline: Implement → Integrate → Test (for pipeline: full fixes — Parallelize is skipped per `implement/SKILL.md` → "Fix Task Routing")
- Quick fix within full pipeline: Implement → Test (for pipeline: quick fixes — Deviation #13)
- Quick fix mode: Implement → Test (all fixes are pipeline: quick)
Test files written by the tester are exempt from this gate — they are verified by execution, not code review.
</HARD-GATE>

## Coverage Criteria

The test-writer subagent uses these rules to determine what tests to write:

1. **Every acceptance criterion** in `plan.md` (per-task `## Test Expectations` blocks + `plan.md`'s per-phase acceptance block) maps to at least one test. Goals.md is the upstream traceability anchor (problem framing) but is NOT the criterion-authoring source — per T9's strip-from-goals contract, acceptance criteria are owned by Plan.
2. **Happy path, error path, and edge cases** for each criterion
3. **Cross-slice interactions** — data flowing between vertical slices
4. **Boundaries** — invalid input, empty state, max limits, auth boundaries
5. **Regression** — any bugs found during implementation (from fix task history in `fixes/`)

## Test Types

| Type | When to write | What it proves | Template |
|------|--------------|----------------|----------|
| Acceptance | Every `plan.md` task-spec criterion (per-task `## Test Expectations`) | Feature works as specified | `acceptance-test.md` |
| Integration | Cross-slice data flow | Components work together correctly | `integration-test.md` |
| E2E | Critical user journeys | Full stack works end-to-end | `e2e-test.md` |
| Boundary | Edge cases from task specs + goals | System handles limits gracefully | `boundary-test.md` |

The test-writer chooses the appropriate type(s) per acceptance criterion. A single criterion may need multiple test types (e.g., "user can register" needs an acceptance test for the happy path, a boundary test for invalid email, and an integration test for the DB write).

## Process Steps

1. **Run full existing test suite** — establish baseline. If tests fail, present failures to user (Pattern 3 — deterministic, don't re-run). User decides:
   - **Dispatch fixes:** Write fix tasks for the baseline failures (same format as test fix tasks), route through the fix pipeline before writing new tests.
   - **Proceed anyway:** Log failures to `reviews/test/baseline-failures.md`. New acceptance tests will run alongside known failures.
   - **Stop:** Halt pipeline.
2. **Write tests** using coverage criteria and test type templates. The test-writer subagent analyzes `plan.md`'s per-task `## Test Expectations` blocks (and `plan.md`'s per-phase acceptance block, if present) — these are the canonical acceptance criteria per T9's strip-from-goals contract. The subagent identifies which test types each criterion needs and writes tests accordingly. Each test maps to a specific acceptance criterion in `plan.md`. `goals.md` is consulted for traceability (every plan-level criterion should trace upstream to a goal's problem statement) but is NOT itself the criterion source.
3. **Review test code** — follows **Review Pattern 1 (Inner Loop)** with 3 reviewers (reusing Implement's template files).

   > **IMPORTANT — Compaction recommended (M53; pre-review-loop).** The test-writer subagent has just returned the test code. Before dispatching the goal-traceability-reviewer, spec-reviewer, and code-quality-reviewer (and Codex reviewers in parallel, if enabled), run `/compact` if context utilization may exceed ~50%. Reviewer prompts each load the test code + `plan.md` (acceptance-criteria source per T9) + `goals.md` (upstream traceability anchor) + the embedded reviewer-boilerplate; running them on a saturated context produces shallow findings.
   - **goal-traceability-reviewer** (`implement/templates/thoroughness/goal-traceability-reviewer.md`): Does each test map to a specific acceptance criterion from `plan.md`'s per-task `## Test Expectations` blocks (and `plan.md`'s per-phase acceptance block)? Does each plan-level criterion trace upstream to a goal's problem statement in `goals.md`? Are any criteria untested? Per T9's strip-from-goals contract, `plan.md` is the criterion-authoring source; `goals.md` is the upstream problem-framing anchor. The reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time. Findings must conform to the M48 5-field schema defined there (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`); `change_type` is required.
   - **spec-reviewer** (`implement/templates/correctness/spec-reviewer.md`): Does the test verify what it claims to? Are assertions meaningful, not vacuous? The reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time. Findings must conform to the M48 5-field schema defined there (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`); `change_type` is required.
   - **code-quality-reviewer** (`implement/templates/correctness/code-quality-reviewer.md`): Is the test reliable? Flaky setup? Race conditions? Proper cleanup? The reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time. Findings must conform to the M48 5-field schema defined there (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`); `change_type` is required.
   - **Codex review** (if `codex_reviews: true`) — dispatch a non-blocking Codex review via the wrapper, with **three explicit launch+await pairs** (one per Claude reviewer template: goal-traceability-reviewer, spec-reviewer, code-quality-reviewer). General rules apply to all three pairs: run launches as foreground Bash-tool calls; the wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds; the orchestrator (this skill's caller — the Claude Code agent driving the Bash tool) records that printed jobId text from each launch Bash call's stdout output and pastes it as the literal `<jobId>` argument in the matching await Bash call for that template below; there is no shell variable assignment in this flow (the **jobId-1 / jobId-2 / jobId-3** labels in the pairs below are *labels for the orchestrator's notes*, not shell variable names), and shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md; if a launch exits non-zero, abort that template's Codex review and append a launch-failure note to the review log (other templates proceed independently). Await **all three** captured jobIds (do not skip awaits if an earlier one fails or hits the ceiling — each template's result is recorded independently); consolidation runs only after the last await returns. Per-await exit codes: **0** = success, append the markdown stdout to `reviews/test/round-NN-review.md` under `#### Codex` beneath that reviewer's `### {reviewer-name}` heading; **10** = 20-min ceiling hit (no stdout produced) — append an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`), do NOT append empty stdout, do NOT silently retry; **11** = companion crash mid-job (job-not-found) — append a crash note and surface to the user before proceeding; **12** = audit-write fail (e.g., row > 4096 bytes) — append an infrastructure-failure note and surface to the user, do NOT retry blindly. **Only append stdout to the review log on exit 0.**

     **Pair 1 — goal-traceability-reviewer:**
     1. Write the review prompt (`implement/templates/thoroughness/goal-traceability-reviewer.md` + the test code + `plan.md` (acceptance-criteria source) + `goals.md` (upstream traceability anchor)) to `/tmp/codex-prompt-test-goal-traceability-reviewer.md`.
     2. At dispatch time (in parallel with the Claude goal-traceability-reviewer), run `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-test-goal-traceability-reviewer.md` as a foreground Bash-tool call. The orchestrator records the printed jobId text from the Bash tool's stdout output under the label **jobId-1** in its notes (label only — not a shell variable) and will paste that exact text as the `<jobId>` argument in the await Bash call below (per the general rules above).
     3. After the Claude reviewers return, run `scripts/codex-companion-bg.sh await <jobId-1>` and apply the per-exit-code handling above; record findings under `### goal-traceability-reviewer` → `#### Codex`.

     **Pair 2 — spec-reviewer:**
     1. Write the review prompt (`implement/templates/correctness/spec-reviewer.md` + the test code + `plan.md` (acceptance-criteria source) + `goals.md` (upstream traceability anchor)) to `/tmp/codex-prompt-test-spec-reviewer.md`.
     2. At dispatch time (in parallel with the Claude spec-reviewer), run `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-test-spec-reviewer.md` as a foreground Bash-tool call. The orchestrator records the printed jobId text from the Bash tool's stdout output under the label **jobId-2** in its notes (label only — not a shell variable) and will paste that exact text as the `<jobId>` argument in the await Bash call below (per the general rules above).
     3. After the Claude reviewers return, run `scripts/codex-companion-bg.sh await <jobId-2>` and apply the per-exit-code handling above; record findings under `### spec-reviewer` → `#### Codex`.

     **Pair 3 — code-quality-reviewer:**
     1. Write the review prompt (`implement/templates/correctness/code-quality-reviewer.md` + the test code + `plan.md` (acceptance-criteria source) + `goals.md` (upstream traceability anchor)) to `/tmp/codex-prompt-test-code-quality-reviewer.md`.
     2. At dispatch time (in parallel with the Claude code-quality-reviewer), run `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-test-code-quality-reviewer.md` as a foreground Bash-tool call. The orchestrator records the printed jobId text from the Bash tool's stdout output under the label **jobId-3** in its notes (label only — not a shell variable) and will paste that exact text as the `<jobId>` argument in the await Bash call below (per the general rules above).
     3. After the Claude reviewers return, run `scripts/codex-companion-bg.sh await <jobId-3>` and apply the per-exit-code handling above; record findings under `### code-quality-reviewer` → `#### Codex`.
   - First pass clean (across both Claude and Codex if enabled) → proceed to coverage gate. Issues found → converge, fix all, re-converge. Up to 3 fix cycles — if unresolved, present to user at coverage gate. Test code fixes stay inside the Test skill — not production code, so the HARD GATE doesn't apply.
4. **Coverage approval gate** — present to user:
   - Tests written (grouped by type: acceptance, integration, E2E, boundary)
   - Coverage reasoning: which acceptance criteria are covered, by which tests
   - Identified gaps: criteria or flows that are hard to test automatically, or where coverage is thin
   - User decides: **approve** (proceed to run) or **add more tests** (user describes what's missing → back to step 2)
5. **Run the approved test suite** — deterministic, run once.
6. **Present results** — complete pass/fail list. User can always request more tests. User decides:
   - **Add more tests:** User identifies missing test scenarios → back to step 2
   - **Dispatch fix tasks:** Send failing tests to the fix pipeline (only if failures)
   - **Accept/Approve:** Proceed to phase routing
   - **Stop:** Halt pipeline

6a. **Update goals.md checkboxes** (runs only when user chooses "Approve" — not during fix-task dispatch):
   - For each criterion in the coverage table where Status=Written and ALL mapped tests passed:
     - Find the matching line in `goals.md`
     - Change `- [ ]` to `- [x]`
     - Match by: (1) bold criterion ID (e.g., `**M24`), or (2) exact criterion text substring
   - Do NOT modify criteria with any failing mapped tests
   - Do NOT modify criteria marked as gaps
   - Display summary: "Updated N/M criteria checkboxes in goals.md"

## Test Fix Loop

**Classify each failure** (full pipeline mode only) as quick fix or full pipeline:

| Signal | Quick fix | Full pipeline |
|---|---|---|
| Files involved | 1-2 files, identifiable from error | 3+ files or unclear scope |
| Fix complexity | Obvious from error (wrong value, missing check) | Requires investigation or design judgment |
| Cross-task impact | Isolated to one task's code | Spans multiple tasks' code |
| Test type | Unit/integration test failure | E2E flow broken across components |

Present per-failure classification to user. User can override any classification before dispatch.

**Quick fix mode (overall pipeline):** Per-failure classification does not apply — all fix tasks are `pipeline: quick` and route to Implement → Test. The classification table is skipped.

**Fix dispatch** (user-confirmed):
1. User confirms → write fix tasks to `fixes/test-round-NN/`. Each fix task includes the **specific test(s) that must pass**.
2. **Full pipeline mode:** Quick fix tasks route to Implement → Test. Full pipeline tasks route through Implement → Integrate → Test. (Parallelize is not invoked for fix-task batches — Implement appends new branch entries to `parallelization.md` per its Fix Task Routing rules.)
3. After fixes return, re-run acceptance tests. If still failing, present to user again. No cycle counting — user is in the loop each time.

**Fix routing note:** The Test orchestrator controls fix task routing — it dispatches Implement as a subagent (the per-task-orchestrator template inside Implement handles the quick vs full distinction based on the task file's `pipeline` field). The subagent returns to the Test orchestrator when done. This is distinct from Implement's normal terminal state routing (which follows config.md) — when Implement is dispatched as a subagent by Test, it does its TDD + review work and returns to the caller, it does not invoke config.md terminal state routing. All input artifacts (`research/summary.md`, `design.md`, etc.) exist in the artifact directory and are available to Implement regardless of whether the overall pipeline is quick or full — Implement reads them based on the task file's `pipeline` field.

## Fix Task File Format

```markdown
---
status: approved
task: NN
phase: {current phase}
pipeline: quick  # or full — based on classification
fix_type: test
---

# Test Fix NN: {description}

- **Files:** {exact paths from error trace}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Description:** {what the test failure reveals and what needs to change}
- **Failing test(s):**
  - `{test file}::{test name}` — {what it expects vs what it gets}
- **Test expectations:**
  - {the specific test(s) listed above must pass after the fix}
  - {all existing tests must still pass}
```

## Artifacts

- `reviews/test/round-NN-review.md` — test results, acceptance coverage, failures. Includes `## Test Code Review` header for Pattern 1 test code review findings (from goal-traceability-reviewer, spec-reviewer, code-quality-reviewer) and `## Test Results` header for test execution pass/fail data.
- `reviews/test/baseline-failures.md` — baseline test failures logged when user chooses "proceed anyway" (if applicable)
- `replan-pending.md` — marker file written before invoking Replan, deleted by Replan on completion (used for resume detection in `using-qrspi`)

## Human Gate

Present test results to the user: which acceptance criteria passed, which failed, overall test suite status. User approves test results before phase routing proceeds. On rejection, write feedback to `feedback/test-round-{NN}.md` and re-run the test fix loop.

## Code Review Checkpoint (Before PR)

After all acceptance tests pass and the user has approved the test results, present a code review window before creating the PR:

```
All acceptance tests passed. Before creating the PR, take time to review the implementation code.

Review options:
1. Local file review — here are all changed files:
   {list each changed file with absolute path}
2. Full phase diff — run: git diff main...HEAD
3. Skip review and continue to PR
```

Wait for the user to choose. Proceed to PR creation only after the user selects an option (including option 3 to skip).

## Phase Learnings Gate

Before proceeding to phase routing, ask the user:

> "Before we proceed to phase routing: do you have any phase learnings or ideas for future phases?
> - **Current-phase items** (things to fix now, constraints found): discuss these in conversation — we'll handle them before moving on.
> - **Future work ideas** (new features, improvements for later phases): these will be appended to `future-goals.md` Ideas section.
> (Press Enter to skip.)"

If the user provides **future work ideas**: append as bullet points under `## Ideas` in `future-goals.md` in the artifact directory. If `## Ideas` section does not exist, create it.

If the user provides **current-phase items**: discuss in conversation and resolve before proceeding to phase routing.

If the user presses Enter or provides no input: skip silently.

## Terminal State — Phase Routing

> **IMPORTANT — Compaction recommended (M53; terminal state).** Acceptance tests passed. This is a good point to compact context before phase routing (PR creation, then either pipeline completion or Replan dispatch). Recommend the user run `/compact` if context utilization may exceed ~50%.

**Every phase gets a PR.** After acceptance testing passes, prepare a PR for the current phase: draft title (including phase number for multi-phase projects), summary referencing artifacts in `docs/qrspi/YYYY-MM-DD-{slug}/`. Show user for confirmation. On confirmation, create PR via `gh pr create`. If user declines (e.g., wants to review locally first), skip PR creation — code stays on the feature branch.

- **Last phase?** → Pipeline complete. Announce completion.
- **More phases?** → Write `replan-pending.md` to the artifact directory (marker for resume detection: contains current phase number and timestamp), then invoke `qrspi:replan` to update remaining tasks based on phase learnings before starting the next phase.

> **IMPORTANT — Compaction recommended (M53; cross-skill transition).** Before invoking the next skill (`qrspi:replan` when more phases remain), run `/compact` if context utilization may exceed ~50%. Replan reads `goals.md` + `design.md` + `plan.md` + every prior phase's review findings + `future-goals.md`; entering it on a saturated context degrades the severity-classification quality and risks misrouting major-vs-minor updates.

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Test-writer subagent | Standard (sonnet) — test writing from specs |
| Test code reviewers | Standard (sonnet) — reusing Implement's templates |
| Fix task writing | Standard (sonnet) — translating failures to task specs |
| Phase routing / PR creation | Fast (haiku) — mechanical |

## Task Tracking (TodoWrite)

Sub-tasks for Test:

1. Run existing test suite
2. Write acceptance tests
3. Review test code (Pattern 1)
4. Present coverage for approval
5. Run approved test suite
6. Present results
7. Dispatch fix tasks (if needed)
8. Phase routing / PR creation

## Red Flags — STOP

- Writing production code to fix a failing test (HARD GATE violation)
- Skipping test code review because "tests are not production code" (test quality matters — flaky tests are worse than no tests)
- Re-running failing tests without code changes (deterministic — same code = same result)
- Writing tests that don't map to any acceptance criterion in `plan.md` (per-task `## Test Expectations` or per-phase acceptance block)
- Writing vacuous tests (assertions that can't fail, like `expect(true).toBe(true)`)
- Classifying all failures as "quick fix" to avoid the Implement → Integrate round trip
- Creating a PR without user confirmation
- Skipping phase routing (invoking Replan) when more phases exist
- Proceeding to PR creation without offering a code review window after tests pass

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "This is a one-line fix, I can just patch it" | Test HARD GATE: all production code goes through Implement with reviews |
| "Tests already passed in Implement" | Acceptance tests verify goals end-to-end, not per-task correctness |
| "The fix is obvious from the failure" | Write the fix task description, not the fix — that's Implement's job |
| "Routing back through the pipeline is wasteful" | The round trip ensures all code is reviewed — that's the invariant |
| "This test failure is flaky, just re-run" | Tests are deterministic. Investigate the failure. If truly flaky, fix the test. |
| "All acceptance criteria are covered by Implement's tests" | Implement tests verify task specs. Acceptance tests verify goals. Different things. |
| "Quick fix classification for everything speeds us up" | Quick fix skips Integrate and the cross-task gates. If the fix spans tasks, you need those gates. |
| "We can create the PR later" | Phase routing happens now. If more phases exist, Replan must run before the next phase. |

## Worked Example — Good Acceptance Test Derivation

Given a `plan.md` task-spec `## Test Expectations` bullet:
```
- TE-1: Clients exceeding 100 requests/min receive 429 Too Many Requests
```

Test-writer produces:

```markdown
## Acceptance Criterion: Rate limit enforcement

### Test 1 (Acceptance): Client exceeding limit receives 429
- Send 101 requests from the same API key within 60 seconds
- Assert: 101st request returns HTTP 429
- Assert: Response body contains error message
- Maps to: plan.md task-04 / TE-1 (upstream goal: M-rate-limit)

### Test 2 (Boundary): Client at exactly the limit is allowed
- Send exactly 100 requests from the same API key within 60 seconds
- Assert: All 100 return HTTP 200
- Maps to: plan.md task-04 / TE-2 (upstream goal: M-rate-limit; boundary — at-limit behavior)

### Test 3 (Boundary): Rate limit resets after window expires
- Send 100 requests, wait for window reset, send 1 more
- Assert: The post-reset request returns HTTP 200
- Maps to: plan.md task-04 / TE-3 (upstream goal: M-rate-limit; boundary — window reset)
```

## Worked Example — Bad (Vague/Vacuous)

```markdown
## Rate Limiting Tests

### Test 1: Rate limiting works
- Test that rate limiting is working correctly
- Assert: Rate limiting works
```

**Why this fails:** "Rate limiting works" is not testable — no specific input, no specific expected output; doesn't map to any acceptance criterion; no boundary testing (at-limit, over-limit, reset); tautological assertion can't fail meaningfully.

## Iron Laws — Final Reminder

The two override-critical rules for Test, restated at end:

1. **NO PRODUCTION CODE FIXES IN THE TEST SKILL.** All fixes route through the pipeline (full: Implement → Integrate → Test; quick: Implement → Test). Test files written by the test-writer are the only exception; they are verified by execution, not by code review.

2. **Every test maps to a specific acceptance criterion in `plan.md`'s task-spec `## Test Expectations` block or `plan.md`'s per-phase acceptance block; `goals.md` provides the upstream traceability anchor only. Tests that don't trace to a criterion are out of scope.** Vacuous assertions (e.g., `expect(true).toBe(true)`) fail this rule because they prove nothing about the criterion.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
