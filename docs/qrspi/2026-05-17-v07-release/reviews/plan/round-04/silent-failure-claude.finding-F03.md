---
finding_id: R4-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1277-L1282
  - docs/qrspi/2026-05-17-v07-release/plan.md:L133-L134
artifact: plan
round: 4
reviewer: silent-failure-claude
---

T42 explicitly acknowledges that its BATS assertions are "documentation-shape assertions" against `skills/replan/SKILL.md` and that runtime promotion behavior is exercised only "as phase-acceptance at Integrate time when the Replan agent actually runs against the fixture during a real phase-boundary handoff." This is a designed-in silent fallback: the BATS pin passes whether or not the Replan agent actually respects the boundary-with-Goals contract at runtime, because the test only checks documentation shape.

The silent-failure gap: the plan specifies no task or mechanism that creates and enforces the Integrate-time runtime test. The Slice 10 acceptance criterion (L133-134) states: "A Replan invocation against a mixed-shape future-goals fixture (one fully Formal entry, one prose-only Idea, one partial-Formal entry) promotes only the fully Formal entry. The hand-off report lists both promoted Formal goals and skipped Ideas, observable as a Replan output artifact." This is listed as a replan-gate checkbox but there is no task in Slice 10 (or elsewhere) that sets up the Integrate-time scenario, dispatches the Replan agent against the fixture, and captures the output for the gate.

T42's test expectations state (L1279): "the runtime promotion behavior is exercised as **phase-acceptance** at Integrate time when the Replan agent actually runs against the fixture during a real phase-boundary handoff. This disambiguation closes the silent-pass risk where a runtime ignoring the contract would still pass markdown-shape BATS assertions." But it does NOT close the silent-pass risk — it defers the runtime check to an event (a "real phase-boundary handoff") that happens outside the v0.7 release itself. The Replan agent will next run during the v0.8 phase boundary. By that point, the acceptance criterion at L133-134 has no observer to enforce it, and the checkbox can be manually ticked without running the agent against the fixture.

The T39 BATS pin (commit hygiene) and T40 (u14-lint) both exercise the actual script behavior by running the scripts in the BATS harness. T42 does not — it only asserts prose shape. The Slice 10 acceptance criterion requires an observable runtime outcome but T42 decouples the runtime from the test harness, making the checkbox unverifiable at release time.

**Fix:** Add a test expectation to T42 that makes the Replan promotion contract verifiable at BATS time without requiring a live Replan agent invocation. One option: the BATS pin asserts that `skills/replan/SKILL.md`'s `## Boundary with Goals` section contains the promotion logic in a form that a grep-and-fixture assertion can exercise (e.g., assert the promotion classifier's three branches are each enumerable against the `tests/fixtures/future-goals-mixed-shape.md` fixture via the documented decision criteria). Alternatively, if the skill body alone is not sufficient for runtime verification, add a note to the Slice 10 acceptance criterion identifying the specific Integrate-phase deliverable that verifies this criterion (e.g., a required Replan dry-run against the fixture during the v0.7 Integrate phase itself, not the next release's real phase boundary). The current plan leaves the Slice 10 runtime acceptance criterion unverifiable within the v0.7 release.
