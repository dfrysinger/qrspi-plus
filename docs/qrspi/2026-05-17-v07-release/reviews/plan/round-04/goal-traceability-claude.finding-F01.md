---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L132-L134
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1277-L1282
artifact: plan
round: 4
reviewer: goal-traceability-claude
---

The Phase 1 Slice 10 acceptance criteria (plan.md lines 132–134) require a runtime Replan
invocation against the mixed-shape fixture:

> - [ ] A Replan invocation against a mixed-shape future-goals fixture (one fully Formal
>   entry, one prose-only Idea, one partial-Formal entry) promotes only the fully Formal
>   entry.
> - [ ] The hand-off report lists both promoted Formal goals and skipped Ideas, observable
>   as a Replan output artifact.

Both criteria are worded as runtime-behavior observations ("A Replan invocation…promotes",
"observable as a Replan output artifact").

T42 is the only task that covers G15 against the fixture. Its test expectations (plan.md
lines 1277–1282) explicitly disclaim runtime coverage:

> "The pin's BATS layer asserts that the codified contract in the skill prose names exactly
> the promotion outcomes and skip reasons enumerated for the fixture entries…; the runtime
> promotion behavior is exercised as **phase-acceptance** at Integrate time when the Replan
> agent actually runs against the fixture during a real phase-boundary handoff."

No other task (T41 or otherwise) authors test expectations for a runtime Replan invocation
against the fixture. The plan has no integration-tier test spec or acceptance-gate task that
covers the runtime promotion path for G15.

This creates a traceability gap: the plan-authored acceptance criteria demand observable
runtime behavior, but the only covering task's test expectations restrict themselves to
documentation-shape assertions and defer the runtime check to "Integrate time" without
provisioning a concrete task or test expectation to exercise it.

**Why it matters:** If the Replan skill's `## Boundary with Goals` section is authored
correctly in T41 but the Replan agent's runtime promotion step misimplements the contract
(e.g., promotes partial-Formal entries anyway or omits the skipped-entry reasons from the
hand-off report), the Slice 10 acceptance criteria as planned will not catch the defect
before the phase gate fires. The BATS pin only validates skill prose shape, not runtime
behavior.

**Resolution options:**

1. Add a runtime integration-tier test expectation to T42 (or a new T42a companion task)
   that exercises the Replan agent against the `future-goals-mixed-shape.md` fixture and
   observes the actual promotion output and hand-off report. This is the complete fix but
   adds scope.

2. Narrow the Slice 10 acceptance criteria to match what the plan actually tests: replace
   the "A Replan invocation…promotes" bullet with wording that acknowledges the BATS pin
   covers documentation shape and that runtime validation is deferred to the next-phase
   Replan run, with a note that the phase gate should include a Replan dry-run against the
   fixture. This is a scope-reduction fix that makes the acceptance criterion honest.

3. Annotate T42's test expectations to name where the runtime gate fires (e.g., "Phase 1
   Integrate task verifies Replan output against the fixture"), making the Integrate
   contract explicit so the acceptance criterion is not silently dropped.

Of these, option 2 or 3 are the lowest-friction corrections without adding new tasks.
Option 2 is preferred because it eliminates the plan-authored-criterion/task-tested-behavior
mismatch directly.
