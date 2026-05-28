---
finding_id: R1-F05
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:389-412
artifact: plan
round: 1
reviewer: spec-claude
---

Task 11 bundles two distinct observable behaviors across two distinct target files without a sizing exception.

**What is bundled:**
1. Orchestrator-side changes in `skills/implement/SKILL.md`: inserting the pre-implementer `qrspi-test-writer` dispatch and the RED-verification gate inside `### Dispatching the Implementer`.
2. Agent-body change in `agents/qrspi-implementer.md`: adding split-mode awareness so the implementer treats prewritten failing tests as the RED input when the named dispatch signal is present.

These are two distinct files and two distinct observable behaviors. The task title explicitly joins them with `+`: "Implement-skill pre-implementer dispatch + RED-verification gate + qrspi-implementer split-mode awareness." The orchestrator gate (behavior in `skills/implement/SKILL.md`) and the implementer agent's response to the gate signal (behavior in `agents/qrspi-implementer.md`) are independently verifiable: the orchestrator gate fires regardless of the implementer's awareness; the implementer's split-mode awareness is only relevant after the gate has dispatched the test-writer. No `sizing_exception` is declared.

The LOC estimate of ~180 is within the per-task 200-LOC budget, so this is a behavior-bundling concern, not a LOC-overflow concern.

**Proposed split:**
- T11a: Edit `skills/implement/SKILL.md` — insert the pre-implementer test-writer dispatch and the RED-verification gate (with classification and proceed/pause decisions). Depends on T08, T10. Test: gate documentation enumerates all four classifications; lightweight bypass documented.
- T11b: Edit `agents/qrspi-implementer.md` — add split-mode awareness keyed on the `prewritten_red_tests:` dispatch signal from T11a. Depends on T11a. Test: agent body documents that when the signal is present, RED-authoring is skipped; GREEN/refactor cycle is unchanged.

If the plan author determines the orchestrator gate and the implementer awareness are inseparable (they must be authored in one dispatch to avoid a transient state where the gate exists but the implementer does not know what to do with the signal), adding `sizing_exception: reusable primitives` with that rationale would document the decision explicitly. The key question is whether T11a could merge to main and pass tests without T11b — if the pre-implementer gate dispatches test-writer output but the implementer then ignores it and re-authors its own RED tests, the gate is live but incomplete. That coupling argument would support the exception. The plan should state it explicitly rather than leaving it implicit.
