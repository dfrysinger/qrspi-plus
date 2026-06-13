---
finding_id: trace-claude-F03
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - docs/qrspi/2026-06-04-v073-release/design.md
---

# F03 — G9 design Pass 4 (regression-guard execution) has no covering task; phase-level acceptance bullet asserts the property but no task carries the work that produces the evidence

## Summary

`design.md` § G9 commits four coordinated passes (line 505):

> Four coordinated passes, applied in order across all 14 active skills:
> Pass 1 — Three-tier content placement. […]
> Pass 2 — Delete script-mechanic restatements outright. […]
> Pass 3 — Prose-density tightening per R8 (from CD-3). […]
> Pass 4 — Regression guard execution. Run the v0.7.2 phase-1 acceptance suite […]
> against the trimmed skill set. Every test passes against the trimmed skills, OR
> a failing test diagnoses a load-bearing rule that was over-trimmed […]. Zero
> regressions on the suite is the gate.

The plan covers Pass 1 / Pass 2 / Pass 3 in the per-skill trim tasks T32–T36 (each
task body names "three-pass G9 trim" or "Pass 1+2+3" explicitly). T37 covers the
footprint measurement; T38 covers the grep audit. **No task in T31–T38 names
running the v0.7.2 phase-1 acceptance suite as task work.**

The phase-1 acceptance block at line 144 carries the assertion:

> The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`) passes
> against the trimmed skill set with zero regressions; …

This is a phase-level acceptance condition, not a task-owned deliverable. Without
a task that owns the suite-run, the trace from G9 Pass 4 → plan-authored
acceptance criterion → covering task has no third edge.

## Why this is borderline (and why I'm filing it at `low`)

The v0.7.2 phase-1 acceptance suite already exists at `tests/acceptance/v07-
phase1/` — it is not new work, just a test invocation. One can argue Pass 4 is
satisfied implicitly by the universal "run the existing test suite before phase
exit" expectation that every release carries. Counter-argument: G9's Pass 4 is
load-bearing on the *escalation back-path* design.md commits — "OR a failing test
diagnoses a load-bearing rule that was over-trimmed (escalate the offending content
from `references/` back into the active skill body, or restore the deleted
boilerplate to `_shared/`)." That escalation path needs an owner. If the suite
fails, who dispatches the re-trim? T32–T36 are sequenced *before* T37/T38 by
dependency declaration; they have no rerun mechanism.

The phase-1 acceptance bullet at line 144 reads as a binary gate (pass/fail), not
as an escalation-aware loop. Design.md G9 acceptance lines 562–563 phrase it the
same way: "Zero regressions on the suite is the gate." So the loop is implicit in
the cross-phase "if a phase gate fails, the phase doesn't advance" semantics, not
explicit in the plan.

## Recommended remediation

One of:

1. Add an explicit T39 (or fold into T38) that names "run `tests/acceptance/v07-
   phase1/` against the post-T32–T36 tree, report results, and on failure dispatch
   re-trim fix-tasks against the offending skill(s)." This makes the regression-
   guard execution a first-class deliverable with an owner.
2. Add a sentence to T32–T36's `Description` block naming "passes the v0.7.2
   phase-1 acceptance suite at task DONE" so each per-skill trim owns its own
   regression check. Higher per-task cost but lowest cross-task coupling.
3. Accept the implicit phase-gate framing and explicitly document in plan.md
   § Phase 1 Acceptance Criteria that the phase-gate is the owner of this G9
   Pass 4 work (no per-task home). This is the lowest-effort fix and matches the
   current shape, but it makes the omission a documented decision rather than a
   gap.

The choice is design-fidelity-preserving for any of (1)/(2)/(3); the current plan
state is ambiguous about whether Pass 4 has an owner at all.
