---
status: approved
task: 14
phase: 1
pipeline: full
goal_ids: [G15]
task_type: code
model: opus
---

# Task 14: G15 Plan sweep-task contract with dependent-test scope

- **Target files:** modify `skills/plan/SKILL.md`; modify `agents/qrspi-plan-reviewer.md`; modify `skills/using-qrspi/SKILL.md`; modify `tests/integration/test-reference-gate-pause.bats`
- **Dependencies:** none. **Blocks:** Task 15 (G18 Plan cross-task consumer surface builds on the same Plan/reviewer/test surfaces).
- **LOC estimate:** ~110

**Overview**

Add the Plan-time sweep-task contract that makes a producing sweep task enumerate dependent tests, or prove none exist, before implementation begins. The Plan skill authors the contract, the Plan reviewer enforces it, shared pipeline guidance routes findings through the existing re-spec loop, and the integration test pins the pause behavior. (Why: see goals.md ### G15. Approach: see design.md ## G15.)

**Scope**

- **In:**
  - Add `skills/plan/SKILL.md` `### Sweep Task Contract` at the end of the Test Expectations section, using the design's required contract language for sweep-task definition, `dependent_tests:` path-list shape, and `dependent_tests: none` plus `grep -rn '<pattern>' tests/` zero-match proof shape.
  - Add the two worked examples under that subsection: one sweep-task excerpt with explicit dependent test paths and per-file dispositions, and one excerpt using the `none` plus grep shape.
  - Add the `agents/qrspi-plan-reviewer.md` sweep-task detection rubric: >5 files of the same extension plus one of the required sweep keywords in title or description, with case-insensitive word-boundary matching.
  - Make the Plan reviewer emit a high-severity correctness finding when a sweep-shaped task lacks `dependent_tests:`, lists malformed paths, omits the required `none` plus grep proof, or provides a grep proof that returns one or more matches from the repository root.
  - Add the `skills/using-qrspi/SKILL.md` backstop note that sweep-task dependent-test findings are ordinary Plan review findings handled by the existing plan re-spec loop.
  - Extend `tests/integration/test-reference-gate-pause.bats` for the positive sweep detection case and malformed `dependent_tests:` variants already named in the existing spec.

- **Out:**
  - Cross-task consumer-surface authoring and reviewer enforcement for `cross_task_consumers:` — Task 15 owns.
  - Consumer-surface-specific assertions in `tests/integration/test-reference-gate-pause.bats` — Task 15 owns.
  - Automated gate-time test discovery, per-task gate script changes, test-runner behavior changes, and `implementer-protocol/SKILL.md` changes — explicitly deferred / excluded by design.md ## G15.

**Definition of done**

- `skills/plan/SKILL.md` contains the new `### Sweep Task Contract` subsection at the end of `## Test Expectations` and preserves the required two valid `dependent_tests:` shapes.
- The Sweep Task Contract includes both worked examples: explicit dependent test paths with per-file dispositions, and `dependent_tests: none` followed by a reproducible zero-match `grep -rn '<pattern>' tests/` command.
- `agents/qrspi-plan-reviewer.md` treats a task as sweep-shaped only when `files_in_scope` lists strictly more than five files of the same extension and the title or description contains one of `all`, `every`, `strip`, `remove`, `rename`, `replace`, `delete`, or `sweep` using case-insensitive word-boundary matching.
- `agents/qrspi-plan-reviewer.md` emits `severity: high, change_type: correctness` for missing or malformed `dependent_tests:` fields, including `none` claims whose grep proof returns one or more matches from the repository root.
- `skills/using-qrspi/SKILL.md` states that sweep-task dependent-test findings route through the normal Plan review and re-spec loop, without introducing a new implementation gate or test-runner behavior.
- `tests/integration/test-reference-gate-pause.bats` covers the positive detection case for more-than-five same-extension files plus a sweep keyword and verifies the missing-field finding pauses the Plan gate.
- `tests/integration/test-reference-gate-pause.bats` covers malformed field variants: no file paths, `none` without the grep command, and `none` with a grep command that returns at least one hit.

**Test expectations**

- Inspect `skills/plan/SKILL.md` to confirm `### Sweep Task Contract` appears at the end of `## Test Expectations`, with the sweep definition, both valid `dependent_tests:` shapes, and both worked examples.
- Inspect `agents/qrspi-plan-reviewer.md` to confirm the sweep heuristic uses strict `>5` same-extension files and the exact eight-keyword list with case-insensitive word-boundary matching.
- Inspect `agents/qrspi-plan-reviewer.md` to confirm missing, malformed, and non-zero-grep `dependent_tests:` cases all produce the existing high-severity correctness finding shape.
- Inspect `skills/using-qrspi/SKILL.md` to confirm the backstop note routes sweep findings through normal Plan review / re-spec handling only.
- Run the targeted `tests/integration/test-reference-gate-pause.bats` cases added for G15 and confirm they cover both the positive missing-field pause and the malformed-field variants.

**References**

- goals.md ### G15 — problem framing for sweep tasks whose dependent tests are outside the producing task's file scope.
- design.md ## G15 — required contract wording, reviewer heuristic, deliverables, exclusions, and v0.7.3 automated-discovery deferral.
- structure.md ### `skills/plan/SKILL.md` — Slice 1.3 Plan authoring block for the Sweep Task Contract and worked examples.
- structure.md ### `agents/qrspi-plan-reviewer.md` — Slice 1.3 reviewer rubric block for sweep-task detection and high-severity findings.
- structure.md ### `skills/using-qrspi/SKILL.md` — existing shared pipeline guidance surface targeted by this task's backstop note.
- structure.md ### `tests/integration/test-reference-gate-pause.bats` — G15 integration coverage for dependent-test pause behavior.
