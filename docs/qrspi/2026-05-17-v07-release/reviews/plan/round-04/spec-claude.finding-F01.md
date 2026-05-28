---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L136-L138
artifact: plan
round: 4
reviewer: spec-claude
---

The `## Task Specs` preamble (plan.md lines 136–138) introduces two new frontmatter fields — `conditional: true` and `conditional_precondition:` — and states that "The Implement orchestrator reads these fields before dispatching the task." However, no task in the plan is responsible for authoring the corresponding documentation of this orchestrator behavior in `skills/implement/SKILL.md`.

The five tasks that edit `skills/implement/SKILL.md` are T05 (routing chain + telemetry), T11 (RED-verification gate + split-mode awareness), T12 (dispatch-order note + task_type defaulting), T27 (reference-gate pause + wave_context + visual-fidelity dispatch), and T39 (worktree-setup exclude). None of their target-file descriptions or test expectations include adding a section documenting how the Implement orchestrator evaluates `conditional:` and `conditional_precondition:` fields before dispatching a task.

The consequence is a documentation gap in the shipped skill: after the v0.7 release, `skills/implement/SKILL.md` will lack any prose describing the conditional-dispatch contract. A future plan author reading the skill to understand how to write a conditional task, or a reviewer checking whether the orchestrator honored a conditional field, will find no authoritative source in the skill body — only the plan's `## Task Specs` preamble, which is a plan-artifact-level concept document rather than a runtime-facing skill section.

**Resolution:** Add a test expectation to one of the tasks that edits `skills/implement/SKILL.md` — most naturally T11 (which already edits the `### Dispatching the Implementer` section) or T05 (routing chain) — requiring that the edited `skills/implement/SKILL.md` body documents the `conditional:` / `conditional_precondition:` orchestrator-dispatch contract: how the orchestrator reads these fields, what happens when the precondition is not met (dispatch is short-circuited; DONE report records `status: skipped` with the verbatim precondition-evaluation result), and that a task without `conditional: true` is unconditionally dispatched. This gives the skill a load-bearing prose section the orchestrator and future authors can key on, closing the gap between the plan-level declaration and the runtime-facing skill body.
