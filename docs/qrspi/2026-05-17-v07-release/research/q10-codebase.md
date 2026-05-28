---
status: draft
question_ids: [10]
research_type: codebase
---

# Q10: How does the TDD cycle inside `skills/implement/SKILL.md` and `agents/qrspi-implementer.md` currently sequence test-writing and production-code writing within a single dispatch, and where does `agents/qrspi-test-writer.md` already plug in (per `test-test-writer-tool-grant.bats`)?

## Summary

**TL;DR:** Inside the Implement skill, the entire TDD cycle (write failing test → verify fail → write minimal production code → verify pass → refactor → commit) runs **inside a single `qrspi-implementer` subagent dispatch per task**; main chat does not split test-writing and production-code into separate subagents. The separate `qrspi-test-writer` agent is **not invoked by Implement at all** — it is the test-writer for the **Test phase (QRSPI Step 11)**, dispatched by `skills/test/SKILL.md` after implementation is complete to author acceptance / integration / e2e / boundary tests against `plan.md` criteria. The bats file `tests/unit/test-test-writer-tool-grant.bats` is a structural frontmatter pin on the `qrspi-test-writer.md` agent file (Read, Write, Grep, Glob in `tools:` and "Survey existing tests before writing" sentence in the body) — it does not assert anything about Implement-phase wiring.

**Key findings:**
- **Single-dispatch TDD inside Implement.** `skills/implement/SKILL.md:529-541` ("TDD Process (inside the implementer subagent)") lists 6 numbered steps — read test expectations, write failing tests, run tests verify fail, write minimal implementation, run tests verify pass, sanity check + commit — all prefixed "Implementer:". The header line states explicitly: "All steps below run inside the **implementer subagent**. Main chat does not run tests, write code, or commit directly."
- **`qrspi-implementer.md` carries the same cycle as RED-GREEN-REFACTOR.** `agents/qrspi-implementer.md:24-33` defines the cycle as: (1) RED — read expectations, write one failing test; (2) Verify RED — run, confirm fail-for-right-reason, abort if vacuous; (3) GREEN — write minimal implementation; (4) Verify GREEN — run ALL tests; (5) REFACTOR — clean up while green; (6) Repeat. Both test-writing and production-code writing happen in the same subagent's context, one test at a time.
- **The Iron Law forbids the alternative.** `agents/qrspi-implementer.md:14-22` and `skills/implement/SKILL.md:442-446` both pin "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" — and the implementer's Red-Flags table at `agents/qrspi-implementer.md:48-60` explicitly forbids "Writing production code before a failing test exists" and "Writing test and implementation in the same step."
- **`qrspi-test-writer` plugs in only at the Test phase (Step 11), not Implement (Step 9).** `skills/test/SKILL.md:28` lists Test Writer as the first of four Test-phase subagent dispatches; `skills/test/SKILL.md:90-100` is the dispatch site ("Write tests — dispatch the test-writer subagent" with `Agent({ subagent_type: "qrspi-test-writer", model: "<plan.test_writer_model || 'sonnet'>" })`). Implement never references `qrspi-test-writer` — `grep -n "test-writer" skills/implement/SKILL.md` returns zero hits.
- **The bats file is a frontmatter pin, not a wiring assertion.** `tests/unit/test-test-writer-tool-grant.bats:1-106` asserts only: (a) `agents/qrspi-test-writer.md` exists, (b) the frontmatter `tools:` line contains all four of Read, Write, Grep, Glob (order-independent), and (c) the body retains the sentence "Survey existing tests before writing". It does NOT assert that the Test phase or Implement phase dispatches the agent.
- **`qrspi-test-writer` agent body confirms its own scope is Test-phase.** `agents/qrspi-test-writer.md:8` states: "You are writing acceptance tests that verify the implementation meets the original goals. You do NOT fix code — you write tests and report failures." Its Iron Law (line 26-27) is "YOU WRITE TESTS AND REPORT COVERAGE. YOU DO NOT FIX CODE OR RUN TESTS." Its dispatch parameters (`agents/qrspi-test-writer.md:11-22`) include `companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir` — matching exactly what `skills/test/SKILL.md:92-99` sends; none of these match the Implement-phase implementer-protocol dispatch contract (`mode`, `task_definition`, `companion_pipeline_inputs`, `companion_review_findings`).

**Surprises:** None — the Implement TDD cycle and Test-phase test-writer are cleanly separated by skill, by dispatch contract, and by agent body.

**Caveats:** Did not exhaust the entire 1355-line `skills/implement/SKILL.md` — read lines 1-300 and 438-700 (the relevant TDD and Per-Task Execution sections) plus the full `qrspi-implementer.md`, full `qrspi-test-writer.md`, full bats file, and lines 1-130 of `skills/test/SKILL.md` plus lines 1-200 of `skills/implementer-protocol/SKILL.md`. Grepped the full implement SKILL for any `test-writer` reference and confirmed zero hits.

## Full findings

### 1. TDD sequencing inside a single implementer dispatch (Implement skill)

**Skill-level statement of sequencing (`skills/implement/SKILL.md:529-541`):**

```
### TDD Process (inside the implementer subagent)

All steps below run inside the **implementer subagent**. Main chat does not run tests, write code, or commit directly.

1. **Implementer: Read test expectations** from the task spec.
2. **Implementer: Write failing tests** based on those expectations.
3. **Implementer: Run tests — verify fail.** If they pass, the test is vacuous — fix it.
4. **Implementer: Write minimal implementation** to make the tests pass.
5. **Implementer: Run tests — verify pass.** If they fail, fix the implementation (not the test).
6. **Implementer: Sanity check and commit.** Implementer-side pass — typecheck / lint green — then commit inside the worktree's git. This is NOT the formal review; formal reviews run next as separate reviewer subagents dispatched by main chat.
```

**Orchestration boundary that pins the single-dispatch shape (`skills/implement/SKILL.md:448-461`):**

- "MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK."
- Main chat does not run tests, write production files, run `git add` / `git commit`, or do "quick verification" between rounds. Each step (writing the failing test, writing the implementation) happens inside the same delegated subagent.

**Dispatch invocation (`skills/implement/SKILL.md:505-507, 514-527`):** A single `Agent({ subagent_type: "qrspi-implementer", model: "<model>" })` dispatch is fired per task per round. Across the per-task fix loop, main chat retains the agent ID and re-enters via `SendMessage` for cycle-2 and cycle-3 fixes — so the same agent instance also handles fix-cycle test/code edits.

### 2. TDD sequencing inside the implementer agent body (`agents/qrspi-implementer.md`)

**Iron Law (lines 14-22):** "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" — with explicit "Write code before the test? Delete it. Start over." follow-up.

**RED-GREEN-REFACTOR (`agents/qrspi-implementer.md:24-33`):**

1. RED — read test expectations from the task spec, write one failing test
2. Verify RED — run, confirm failure for the right reason; if it passes on first run STOP — test is vacuous, fix it before continuing
3. GREEN — write minimal implementation to pass the test; only enough code to make the test green
4. Verify GREEN — run ALL tests; if a test fails, fix the implementation (not the test)
5. REFACTOR — clean up while keeping all tests green
6. Repeat for the next test expectation

**Red Flags that pin the no-split rule (`agents/qrspi-implementer.md:48-60`):**

- "Writing production code before a failing test exists"
- "Writing test and implementation in the same step"
- "'I'll add tests after' or 'this is too simple to test'"
- "Skipping the 'verify fail' step"
- "Committing without all tests passing"

**Common Rationalizations (`agents/qrspi-implementer.md:64-72`):** explicitly rebuts "I'll test after implementing" with "Tests written after pass immediately — they prove nothing."

**Shared protocol (`skills/implementer-protocol/SKILL.md:8, 31-34, 124, 128-137`):** Path-specific TDD discipline lives in the agent file; the shared protocol carries the dispatch shape (`mode: implement` or `mode: fix`), Done Signal (tests pass, build, typecheck, lint, commit), and the BLOCKED escape hatch.

### 3. Where `qrspi-test-writer` plugs in

**It does NOT plug in inside Implement.** A grep of `skills/implement/SKILL.md` for `test-writer` returns zero matches. The implementer subagent writes its own RED tests as the first half of every TDD cycle — there is no separate test-writer dispatch within the per-task TDD loop.

**It plugs in inside `skills/test/SKILL.md` (Step 11 — Test phase).** The dispatch site:

- `skills/test/SKILL.md:14` — "The test-writer subagent (clean context) writes tests and produces a coverage analysis. The orchestrating skill (main conversation) runs the tests, manages the review loop, writes fix task descriptions for failures, and handles phase routing."
- `skills/test/SKILL.md:28` — Subagent roster table: "Test Writer | `qrspi-test-writer` | Writes acceptance/integration/e2e/boundary tests from plan.md acceptance criteria; reports coverage. Does NOT fix code."
- `skills/test/SKILL.md:90-100` — Process step 2: "Write tests — dispatch the test-writer subagent. Read `test_writer_model` from `plan.md` frontmatter (default `sonnet` if missing). Dispatch `Agent({ subagent_type: "qrspi-test-writer", model: "<plan.test_writer_model || 'sonnet'>" })` with a prompt containing only: `companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir`."
- `skills/plan/SKILL.md:172` — `plan.md` frontmatter field `test_writer_model: sonnet` is the per-phase model override for this dispatch.

**The test-writer's scope (per its own body, `agents/qrspi-test-writer.md:8, 26-27`):**

- "You are writing acceptance tests that verify the implementation meets the original goals. You do NOT fix code — you write tests and report failures."
- Iron Law: "YOU WRITE TESTS AND REPORT COVERAGE. YOU DO NOT FIX CODE OR RUN TESTS. Test execution and fix task dispatch are handled by the orchestrating skill, not by you."
- Process step 1 (`agents/qrspi-test-writer.md:34`): reads all acceptance criteria from `companion_plan` — "every task's `## Test Expectations` block, plus `plan.md`'s per-phase acceptance block if present."
- Test type templates (`agents/qrspi-test-writer.md:48-135`): four types — Acceptance, Boundary, E2E, Integration — none of which are the unit-level RED tests written inside an Implement TDD cycle. These are post-implementation acceptance / integration / e2e / boundary tests.

**Dispatch-shape disjointness with the Implement implementer:**

- Implement's `qrspi-implementer` dispatch (`skills/implementer-protocol/SKILL.md:14-22`) takes: `mode`, `task_definition`, `companion_pipeline_inputs`, `companion_review_findings` (fix mode only).
- Test's `qrspi-test-writer` dispatch (`skills/test/SKILL.md:92-99` and `agents/qrspi-test-writer.md:11-22`) takes: `companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir`.

The two contracts share no parameter names; neither agent body reads the other's parameters. The agents are not interchangeable.

### 4. What `tests/unit/test-test-writer-tool-grant.bats` asserts

The bats file (107 lines) is a **structural pin on `agents/qrspi-test-writer.md` frontmatter** — described in its own header as "Structural pin for agents/qrspi-test-writer.md tool-grant contract per the test-writer task spec. Asserts the frontmatter `tools:` line carries all four read-side tools and that the body prose justifying the grant is still present."

**The assertions, in full:**

1. `agent file exists` (line 25-27) — file `$BATS_TEST_DIRNAME/../../agents/qrspi-test-writer.md` is present.
2. `frontmatter tools: line exists in frontmatter` (line 33-40) — a `tools:` key is present within the first `---` block.
3. `frontmatter tools: line contains Read` (line 46-57) — order-independent `grep -qw "Read"` against the tools line.
4. `frontmatter tools: line contains Write` (line 59-70) — same for `Write`.
5. `frontmatter tools: line contains Grep` (line 72-83) — same for `Grep`.
6. `frontmatter tools: line contains Glob` (line 85-96) — same for `Glob`.
7. `agent body contains Survey existing tests before writing sentence` (line 102-106) — `grep -qF "Survey existing tests before writing"` against the body (after the second `---`).

**What the bats does NOT assert:**

- It does not assert which skill dispatches `qrspi-test-writer`.
- It does not pin the dispatch parameters or the Iron Law.
- It does not pin the agent's relationship (or non-relationship) to `qrspi-implementer` or to the Implement skill.
- It does not pin where in the QRSPI pipeline the agent runs.

**Where the bats finds the agent on disk:** `agents/qrspi-test-writer.md` — confirmed by `agents/qrspi-test-writer.md:2` (`name: qrspi-test-writer`) and the agent file's frontmatter line `tools: Read, Write, Grep, Glob` (line 4).

### 5. Diagram of the two flows

```
Implement (Step 9) — per task:
  main chat ── Agent(qrspi-implementer, mode=implement) ─┐
                                                          ├── [inside same subagent]
                                                          │     1. Read test expectations
                                                          │     2. Write failing test (RED)
                                                          │     3. Run — verify fail
                                                          │     4. Write min implementation (GREEN)
                                                          │     5. Run ALL — verify pass
                                                          │     6. Refactor
                                                          │     7. Commit
                                                          ↓
                                                       DONE / DONE_WITH_CONCERNS / BLOCKED
                                                       ↓
                                                       (main chat fans out per-task reviewers)

Test (Step 11) — once per phase, AFTER Implement (and Integrate, in full pipeline):
  main chat ── Agent(qrspi-test-writer, model=test_writer_model) ─→ writes acceptance / integration / e2e / boundary tests to output_dir, returns coverage analysis (does NOT run them)
            ── main chat then runs the tests itself and routes failures back through Implement
```

The two flows are sequential in the pipeline (Step 9 before Step 11), not nested. The implementer's RED-GREEN-REFACTOR is unit-test-level; the test-writer's output is acceptance-criterion-level. They do not coordinate on the same test files within a single dispatch.
