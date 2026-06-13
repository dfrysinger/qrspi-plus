---
finding_id: trace-claude-F02
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
round: 2
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
---

# F02 — T13b (G5 revert-orchestration-drift mode) is missing from T36's dependency list; the implementer-protocol trim pass has no commitment to preserve T13b's addition through the trim

## Summary

Round-02 split round-01's T13 into T13a (G2 — promote Pre-DONE self-check to
blocking) and T13b (G5 — add `revert-orchestration-drift` fix-task mode with
halt-on-conflict). Both tasks modify the same file: `skills/implementer-
protocol/SKILL.md`. T36 — the bulk trim pass for the 7 cross-cutting skills —
trims `skills/implementer-protocol/SKILL.md` and explicitly lists T13a as a
dependency whose addition must survive the trim. T36 does NOT list T13b in its
dependency set, and T36's description does NOT name T13b's
`revert-orchestration-drift` mode as preserved-through-trim content.

This is a structure-fidelity gap: design.md G5 commits both the
HARD-RULE/observability surface AND the `revert-orchestration-drift` fix-task
mode (the autopilot's correction mechanism). T36 protects the HARD-RULE
preservation in `integrate/SKILL.md`/`test/SKILL.md` and the Pre-DONE blocking
sentence in `implementer-protocol/SKILL.md` but leaves the
revert-orchestration-drift mode unprotected against the trim pass.

## Evidence — T36 deps and description

`plan.md` § T36 Dependencies (line 775):

> - **Dependencies:** T07, T31, T13a, T21, T22

T13b is absent.

`plan.md` § T36 Description (line 781, emphasis added):

> Each of the seven cross-cutting skills applies the three-tier placement plus
> deletion plus R8 tightening passes against its **post-T13a/T21/T22 state**.
> **The G2 promotion-to-blocking sentence (T13a) in
> `implementer-protocol/SKILL.md`**, and the verbatim HARD-RULE Orchestration
> Boundary sections plus phase-base.txt write steps in `integrate/SKILL.md`
> and `test/SKILL.md` (T21, T22), are preserved through the trim […]

The "post-T13a/T21/T22 state" phrasing pins T36's input state to a tree that
may or may not contain T13b's addition; the "preserved through the trim" list
explicitly names T13a's sentence but does NOT name T13b's
`revert-orchestration-drift` fix-task mode as preservation-required content.

`plan.md` § Dependency graph block (line 125):

> T07 + T31 + T13a + T21 + T22 → T36 (7 cross-cutting skill trim — T13a carries
> the Pre-DONE blocking prose)

The graph also omits T13b from T36's upstream set and only annotates T13a as
the implementer-protocol carry-through.

## Why this matters for traceability

Design.md G5 commits a three-part change set: (a) inline HARD-RULE in
integrate+test, (b) runtime observability hook (the OBC script), (c) the
batch-gate menu / autopilot integration including the auto-revert path. The
auto-revert path is the *correction mechanism* — without it, the OBC report
surfaces violations but the autopilot has no automated way to clean them up.
T13b is the plan-side decomposition of that mechanism.

Two concrete failure modes the gap exposes:

1. **Schedule-order vulnerability.** T13b's only declared dependency is T19.
   T36's deps are T07/T31/T13a/T21/T22. If the wave-scheduler dispatches T36
   in parallel with T13b (both are eligible once their deps are satisfied),
   T36 trims `implementer-protocol/SKILL.md` against a tree state that does
   not include T13b's new fix-task mode. The mode then either lands on top of
   a trimmed file (re-introducing the un-trimmed prose-density problems R8 was
   meant to fix) or gets dropped on rebase if the trim conflicts.

2. **Preservation contract gap.** T36's Test expectations enumerate which
   prose must survive the trim — T13a's blocking sentence, the HARD-RULE
   blocks, the phase-base.txt write steps. T13b's revert-orchestration-drift
   mode is not on that list. A reviewer scoring T36 against its own test
   expectations would not flag the absence of T13b's mode in the post-trim
   file as a test failure, because no expectation names it.

T13b is correctly traced to G5 (the task carries `goal_ids: [G5]`); the gap is
purely in T36's dependency declaration and preservation contract, not in
backward traceability of T13b itself.

## Recommended remediation

Add T13b to T36's dependency set and to T36's preservation contract:

1. **Dependencies line (T36):** change `T07, T31, T13a, T21, T22` to
   `T07, T31, T13a, T13b, T21, T22`.

2. **Description (T36):** change "post-T13a/T21/T22 state" to
   "post-T13a/T13b/T21/T22 state" and add the
   `revert-orchestration-drift` fix-task mode to the explicitly-named
   "preserved through the trim" list alongside T13a's blocking sentence.

3. **Test expectations (T36):** add a finding-to-verify bullet naming
   preservation of the T13b mode entry through the trim (parallel shape to
   the existing T13a preservation bullet).

4. **Dependency graph block (lines 120–127):** update the T36 row to
   `T07 + T31 + T13a + T13b + T21 + T22 → T36` and update the annotation
   accordingly (e.g., "T13a carries the Pre-DONE blocking prose; T13b carries
   the revert-orchestration-drift fix-task mode").

The change is mechanical (4 textual edits, all in plan.md, no design.md
amendment required because the existing G5 design language already commits
both T13a's and T13b's content as preservation-required).
