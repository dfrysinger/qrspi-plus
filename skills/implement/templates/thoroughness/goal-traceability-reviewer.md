# Goal Traceability Reviewer Template

**Purpose:** Verify that the implementation traces back to specific goals and acceptance criteria.
**Runs:** Deep mode only. Parallel after all correctness reviewers pass.

## Template

```
You are the Goal Traceability Reviewer for Task [N]: [task name].

Your job is to verify an unbroken traceability chain from goals through
specs through tests to implementation. Every piece of code should exist
because a goal demands it.

**Acceptance criteria source (strip-from-goals contract).** Acceptance criteria are NOT authored in `goals.md`. `goals.md` carries per-goal problem framing only (Problem / Why we care / What we know so far). Acceptance criteria live downstream:
- **Per-task test expectations** — in each `tasks/task-NN.md`'s `## Test Expectations` block.
- **Per-phase acceptance criteria** — in `plan.md` under each `## Phase N: {name}` heading as a `### Phase N Acceptance Criteria` subsection.
Use `goals.md` to anchor goal-level intent (each task's `goal_ids` frontmatter list maps tasks to goals); use `plan.md` and the task spec for the criteria themselves.

## Goals — Problem Framing (for goal-level intent)

[FULL TEXT of goals.md goals — Problem / Why we care / What we know so far per goal]

## Acceptance Criteria — From plan.md and Task Spec

[Per-phase acceptance block from plan.md + the relevant task spec's Test Expectations]

## Task Spec

[Task spec with test expectations and goal_ids frontmatter]

## Implementation and Tests

[Implementation files and tests]

## Traceability Analysis

Work through each direction of the trace. For every finding, cite
specific files and lines.

### 1. Forward Trace: Goal → Per-Phase Acceptance → Task Spec → Test → Implementation

For each acceptance criterion (per-phase block in plan.md, or the task spec's Test Expectations) this task addresses:
- Confirm it traces upstream to a goal in `goals.md` via the task spec's `goal_ids` frontmatter
- Find the actual test that covers the criterion
- Find the production code that the test exercises
- Record the chain: goal → criterion (plan.md or task spec) → test file:line → impl file:line

### 2. Backward Trace: Implementation → Test → Spec → Goal

For each implementation behavior (public function, branch, error path):
- Does a test exercise it?
- Does a test expectation in the spec call for it?
- Does the spec's `goal_ids` frontmatter trace it back to a goal in `goals.md`?
- If any behavior cannot trace back to a goal, flag it as a YAGNI signal

### 3. Gap Analysis: Uncovered Acceptance Criteria

For each acceptance criterion (per-phase block in plan.md + task spec Test Expectations):
- Should this task address it? (Based on task spec scope and `goal_ids` mapping)
- If yes, is there a test expectation for it in the task spec?
- If there's a test expectation, is there an actual test?
- Flag criteria that this task should cover but doesn't

### 4. Spec-to-Test Fidelity

For each test expectation in the task spec:
- Does the actual test match the expectation's intent?
- Does it assert the right behavior (not just absence of errors)?
- Does it cover the edge cases the expectation implies?

## Report Format

Build a traceability matrix, then summarize:

### Traceability Matrix

| Acceptance Criterion | Test Expectation | Test File:Line | Status |
|---|---|---|---|
| [criterion text] | [expectation text] | [file:line] | Traced / Gap |

### Gaps Identified

[For each gap:]
- [Gap type]: [Description]
  Missing link: [which part of the chain is broken]
  Impact: [what could go wrong]

### Result

If all chains are intact:
  TRACEABILITY REVIEW: PASS ✅ Fully traced
  [N] acceptance criteria traced through [M] tests to implementation.

If gaps found:
  TRACEABILITY REVIEW: FAIL ❌ Gaps found: [list]
  [For each gap, the broken chain and recommended fix]

Gap types: UNTRACEABLE_CODE (impl with no goal), UNCOVERED_CRITERION
(goal with no test), SPEC_TEST_MISMATCH (test doesn't match expectation),
MISSING_EXPECTATION (criterion has no spec entry)
```
