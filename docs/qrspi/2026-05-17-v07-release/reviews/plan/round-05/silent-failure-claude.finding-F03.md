---
finding_id: R5-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L133-L135
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1279-L1289
artifact: plan
round: 5
reviewer: silent-failure-claude
---

The round-4 fix (R4-F03) added a third Slice 10 acceptance bullet at L135: "the v0.7 Integrate phase MUST include a Replan dry-run against `tests/fixtures/future-goals-mixed-shape.md` and capture the hand-off output for the gate (NOT deferred to the next-release real phase boundary)." This is an improvement over deferring to the next real phase boundary.

However, there is no task in the plan that actually implements this requirement. The Slice 10 task set consists of T41 (prose contract in SKILL.md) and T42 (BATS pin for documentation-shape assertions). Neither task adds anything to the Integrate skill, the Implement skill, or any gate mechanism that would structurally ensure the Replan dry-run is dispatched during v0.7 Integrate. The acceptance criterion at L135 says the Integrate phase MUST include it, but there is no task that:
- Extends `skills/integrate/SKILL.md` with a step requiring the Replan dry-run when G15 is in scope
- Adds a gate artifact (e.g., `reviews/replan-boundary-dry-run.md`) that must be produced before Integrate marks the phase complete
- Authors the dry-run dispatch into an acceptance-test fixture

The result is a designed-in silent pass: at v0.7 Integrate time, the checkbox at L135 can be ticked by any operator regardless of whether the Replan dry-run was actually performed. The plan relies on an out-of-band human commitment ("MUST include") with no structural enforcement. This is the same silent-failure shape that R4-F03 identified — the fix acknowledged the problem but the structural enforcement mechanism (a task that creates the gate) was not added.

T42's test expectations at L1279 explicitly document: "the runtime promotion behavior is exercised as **phase-acceptance** at Integrate time when the Replan agent actually runs against the fixture during a real phase-boundary handoff." The third bullet at L135 asserts this MUST happen in v0.7, but the plan contains no implementation task that makes this observable or required by the Integrate gate.

**Fix:** Add a test expectation to T42 (or a new lightweight task in Slice 10 between T42 and the close of the phase) that creates a machine-readable gate artifact (e.g., a required `tests/fixtures/replan-boundary-dry-run-expected.md` fixture with expected hand-off report shape, plus a T42 assertion that this expected fixture exists) so the Integrate-phase acceptance step has a concrete deliverable to check against rather than relying on a human to remember to run the dry-run. Alternatively, if a structural enforcement task is out of scope for the plan, the Slice 10 acceptance bullet at L135 should explicitly name the Integrate-phase artifact that must be produced (e.g., "the Integrate-phase MUST produce `reviews/tasks/replan-boundary-dry-run.md` containing the captured hand-off output, and the Integrate gate MUST fail if this file is absent") so the pass condition is checkable without human judgment.
