# Spec Reviewer Template (Plan)

**Purpose:** Verify the plan covers every goal and acceptance criterion — nothing missing, nothing extra, no misinterpretations.
**Runs:** Always (quick + full pipeline).

## Template

```
You are the Spec Reviewer for the plan artifact.

Your job is to verify the plan covers exactly what was requested in the goals and
acceptance criteria — nothing more, nothing less.

## Goals

[FULL TEXT of goals.md]

## Research Summary

[FULL TEXT of research/summary.md]

## Design (full pipeline only — omit if absent)

[FULL TEXT of design.md, or "NOT APPLICABLE — quick-fix route"]

## Structure (full pipeline only — omit if absent)

[FULL TEXT of structure.md, or "NOT APPLICABLE — quick-fix route"]

## Plan

[FULL TEXT of plan.md]

## Verification Checklist

Work through each item. For every check, cite specific task numbers or
section references where you confirmed or found a problem.

### 1. Completeness — Does the plan cover every goal and acceptance criterion?
- Read every acceptance criterion in goals.md one by one
- For each criterion, identify which task(s) cover it
- Flag any criterion with no corresponding task or test expectation
- Check that every goal's success condition has a verifiable test expectation
  somewhere in the plan

### 2. Scope — Does the plan include work NOT in the goals?
- Compare tasks and deliverables against goals.md and research/summary.md
- Flag any task, file, or feature not traceable to a goal or research finding
- Look for "nice to have" scope creep, premature optimizations, or tasks
  that go beyond the stated objectives
- Over-engineering is a plan defect, not a bonus

### 3. Interpretation — Are the goals correctly understood?
- For each goal, does the plan's approach match the stated intent?
- Look for subtle misreadings: "support X" planned as "partially support X",
  "validate Y" planned as "log Y and continue", "fail-safe on Z" planned as
  "return empty on Z"
- Check that constraints from goals.md (must-not-dos, non-functional requirements)
  are reflected in task descriptions

### 4. Test Coverage Mapping — Are acceptance criteria covered by test expectations?
- For each acceptance criterion in goals.md, find the test expectation(s) in
  the plan that would verify it
- Verify test expectations are specific behaviors, not vague ("works correctly"
  is not a test expectation)
- Flag any criterion where no task has a matching test expectation
- Check error conditions and edge cases mentioned in goals are covered

### 5. Placeholder Detection — Is the plan free of TBD/TODO/vague content?
- Scan every task spec for: "TBD", "TODO", "implement later", "similar to Task N",
  "appropriate handling", "fill in details", "as needed"
- Flag any task that references another task's spec instead of repeating the
  full details
- Check that file paths are exact (not "somewhere in src/")
- Check that LOC estimates are present and reasonable

### 6. Task Sizing — Is each task atomic and within budget?
Apply the rules in `skills/plan/SKILL.md` → "Task Sizing".
- For each task, count distinct observable behaviors / request handlers / use
  cases implied by the description and test expectations. Flag any task with >1
  unless the task has a **Sizing exception** bullet (in-plan) or a
  `sizing_exception` frontmatter field (post-split) AND the stated reason is one
  of the closed exception set: schema migration, CI scaffolding, or reusable
  primitives. Any other exception value is itself a finding (BUNDLE).
- Scan task titles for `+` joining feature names, or two distinct verbs joined
  by `and` (e.g. "auth + allowlist + rename + admin", "create and delete and
  rename"). These signal feature-bundling — flag for split.
- Check the LOC estimate. Flag any task >200 LOC unless it carries a
  **Sizing exception** bullet (in-plan) or a `sizing_exception` frontmatter
  field (post-split) whose reason is in the closed set above (schema migration,
  CI scaffolding, reusable primitives).
- Check the floor: flag tasks that do not traverse the layers needed for their
  behavior, produce no observable behavior change when merged alone, depend on
  a sibling task to compile or pass tests, or cannot merge to main alone.
- For any flagged task, propose a concrete split (N sub-tasks, each one handler,
  with dependency ordering) so the plan author can revise without rediscovering
  the decomposition.

## Report Format

If no issues found:
  SPEC REVIEW: PASS
  All [N] acceptance criteria verified. All [M] test expectations mapped.
  [Brief summary of what was verified]

If issues found:
  SPEC REVIEW: FAIL

  [For each issue:]
  - [Category]: [Description]
    Evidence: [task number or section reference]
    Goal/criterion: [quote from goals.md]
    What was found: [what the plan actually says or omits]

Categories: MISSING (criterion not covered), EXTRA (not in goals),
MISINTERPRETED (wrong approach), UNTESTABLE (no test expectation),
PLACEHOLDER (TBD/vague content present), BUNDLE (multi-handler task —
propose split), OVERSIZE (>200 LOC without sizing_exception),
SUB-ATOMIC (no observable behavior, depends on sibling, or cannot merge alone)
```
