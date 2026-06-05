---
status: approved
task: 15
phase: 1
pipeline: full
goal_ids: [G18]
task_type: code
model: opus
---

# Task 15: G18 Plan cross-task consumer surface

- **Target files:** skills/plan/SKILL.md (modify), agents/qrspi-plan-reviewer.md (modify), tests/integration/test-reference-gate-pause.bats (modify)
- **Dependencies:** Task 14
- **LOC estimate:** ~130

**Overview**

Add the Plan authoring contract and plan-reviewer enforcement for `cross_task_consumers:` so contract-carrier changes enumerate downstream consumers before implementation, then pin the trigger/no-trigger and malformed-field cases in the existing reference-gate integration test. This preserves G15's separate sweep-task contract while generalizing the under-scoping prevention pattern to named consumer surfaces. (Why: see goals.md ### G18. Approach: see design.md ## G18.)

**Scope**

- **In:**
  - Document a `### Cross-Task Consumer Surface` subsection in `skills/plan/SKILL.md` under task-definition guidance, including the five consumer-surface trigger classes, body-only/prose-only non-trigger guidance, and the two valid `cross_task_consumers:` shapes.
  - Add worked examples in `skills/plan/SKILL.md`: a public-symbol rename with three consumers using `co-edit`, `co-edit`, and `no change` dispositions, plus a body-only bug fix where the field is not required.
  - State in `skills/plan/SKILL.md` that tasks satisfying both the sweep-task trigger and consumer-surface trigger carry both `dependent_tests:` and `cross_task_consumers:` as separate fields.
  - Extend `agents/qrspi-plan-reviewer.md` with the Cross-Task Consumer Surface Detection rubric clause, enforcing field presence, shape, `none` search re-verification, allowed disposition vocabulary, and existing follow-up task IDs for `break-and-fix-task`.
  - Extend `tests/integration/test-reference-gate-pause.bats` to cover the missing-field pause, false `none` claim, disposition vocabulary and follow-up-task validation, and independent findings when a task is both sweep-shaped and consumer-surface-touching.

- **Out:**
  - Changing G15's `dependent_tests:` sweep-task contract — T14 owns the Plan sweep-task contract, and this task only preserves its separate composition with G18.
  - Adding a standalone Plan-phase scope-completeness reviewer subagent or automated grep gate beyond the plan-reviewer rerun of author-supplied `none` commands — design.md ## G18 defers those mechanisms to v0.7.3+.
  - Modifying `implementer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, the Standard Plan loop, per-task gate runner, or broader test infrastructure — design.md ## G18 explicitly leaves downstream phases to consume the enriched plan unchanged.

**Definition of done**

- `skills/plan/SKILL.md` contains a `### Cross-Task Consumer Surface` subsection at the end of task-definition guidance with all five trigger classes from design.md ## G18 and the non-trigger case for body-only callable changes, prose edits without anchor-name changes, and formatting fixes.
- The `cross_task_consumers:` contract in `skills/plan/SKILL.md` accepts exactly two shapes: consumer paths with one-sentence dispositions, or `none` followed by a reproducible zero-result search command.
- The allowed consumer dispositions are exactly `no change`, `pass-through`, `co-edit`, and `break-and-fix-task`, with `break-and-fix-task` requiring a cited existing follow-up task ID.
- `skills/plan/SKILL.md` includes the two worked examples named in design.md ## G18 and states that sweep-shaped consumer-surface-touching tasks carry both `dependent_tests:` and `cross_task_consumers:` as separate fields.
- `agents/qrspi-plan-reviewer.md` detects consumer-surface-touching tasks using the Plan contract and emits `severity: high, change_type: correctness` findings for missing fields, malformed fields, non-zero-hit `none` claims, invalid dispositions, or missing follow-up task IDs.
- `tests/integration/test-reference-gate-pause.bats` covers the G18 trigger/no-trigger enforcement surfaces listed in the original task expectations, including the independent-finding case for tasks that satisfy both G15 and G18 triggers.

**Test expectations**

- Grep `skills/plan/SKILL.md` for `### Cross-Task Consumer Surface`, the five trigger-class anchor phrases, the non-trigger sentence, both `cross_task_consumers:` shapes, all four disposition strings, and the sweep-plus-consumer composition note.
- Inspect the worked examples in `skills/plan/SKILL.md` to verify one public-symbol rename example lists three consumers with `co-edit` / `co-edit` / `no change`, and one body-only bug-fix example explains why the trigger does not fire.
- Grep `agents/qrspi-plan-reviewer.md` for the Cross-task consumer surface detection rubric and verify it checks field presence/shape, reruns `none` search commands from repo root, validates disposition vocabulary, validates `break-and-fix-task` follow-up task IDs, and emits `severity: high, change_type: correctness` findings.
- Run the targeted `tests/integration/test-reference-gate-pause.bats` cases covering a consumer-surface-touching task without `cross_task_consumers:`, a false `cross_task_consumers: none` claim, invalid dispositions / missing follow-up task IDs, and a task missing both `dependent_tests:` and `cross_task_consumers:`.
- Confirm the G18 changes do not merge or rename G15's `dependent_tests:` contract and do not require changes outside the three target files.

**References**

- goals.md ### G18 — problem framing for Plan-phase under-scoping of cross-task consumer surfaces.
- design.md ## G18 — author-side template extension, reviewer-side heuristic, worked examples, and G15/G18 composition rule.
- structure.md ### `skills/plan/SKILL.md` — target block for the Plan authoring contract, worked examples, and composition note.
- structure.md ### `agents/qrspi-plan-reviewer.md` — target block for reviewer enforcement of the Cross-Task Consumer Surface Detection clause.
- structure.md ### `tests/integration/test-reference-gate-pause.bats` — target block for integration coverage of G18 pause behavior and field-shape failures.
