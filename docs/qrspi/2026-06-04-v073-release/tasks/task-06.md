---
status: approved
task: 6
phase: 1
pipeline: full
goal_ids: [CD-2, G9]
task_type: tdd
tier: low
---

# Task 06: Create tests/lint/test-no-diff-redirect-prose.bats

- **Target files:** `tests/lint/test-no-diff-redirect-prose.bats` (Create)
- **Dependencies:** T05
- **LOC estimate:** ~25
- **Description:** A grep audit asserts zero `git diff > round-NN.diff` Bash redirect blocks remain in the eight artifact-step SKILL.md files after T05's pass. The lint runs in CI on every PR and prevents reintroduction of the per-step diff-emission prose pattern this task retires.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - "Skill-body prose audit: zero `git diff > round-NN.diff` Bash redirect blocks remain in `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md`" (CD-2 Acceptance bullet 3, verbatim).
  - The lint fails against a fixture skill body that re-introduces the redirect pattern (fail-direction guard).
  - The lint's failure output names the offending file, line number, and the `git diff > round-NN.diff` redirect pattern (named-diagnostic discipline; no silent non-zero exit) — matches the T12/T18/T24 sibling-lint output discipline.
  - The lint's pattern is scoped to the eight artifact-step skills only — a benign occurrence of the literal string in an unrelated skill body or test fixture does not trigger a false positive.
