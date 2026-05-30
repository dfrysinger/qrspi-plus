# Finding F11: Task 10 — Manual smoke test presented as an automatable test expectation

**Artifact:** plan.md
**Task:** Task 10 (G7b part 2 — per-host model_routing resolution)
**Category:** Test Expectation Quality
**Severity:** blocking

## Problem

The last test expectation is:

> "A freshly installed copy of the plugin on Copilot CLI emits zero 'model not available' warnings when an agent dispatch resolves through the `model_routing` table"

`design.md`'s Test Strategy section explicitly labels this as a **manual regression smoke test**:

> "Regression smoke (manual): fresh `copilot plugin install` on the resulting branch shows zero 'model not available' warnings across a full pipeline run."

The plan's expectation, however, is listed alongside the automated BATS assertions with no "manual" qualifier. A test writer following the plan would attempt to generate an automated BATS test from this expectation — which is impossible, because it requires:
- A live Copilot CLI installation,
- A real `copilot plugin install` invocation,
- An actual agent dispatch that goes through the live routing stack.

None of these steps are available to the BATS test harness. An automated test written for this expectation would either be a no-op stub (always passes) or would require infrastructure unavailable in CI.

If the test writer treats this as automatable, they will write a test that cannot fail and therefore cannot verify the invariant.

## Recommendation

Mark this expectation explicitly as a **manual verification step** outside the automated test suite:

- *(Manual smoke — not automatable in BATS CI)* "A freshly installed copy of the plugin on Copilot CLI emits zero 'model not available' warnings when an agent dispatch resolves through the `model_routing` table."

And add a corresponding automated proxy expectation:

- "The structural lint assertions for each `copilot-cli` `model_routing` entry verify that the value is not a bare Claude tier short-form (`haiku`, `sonnet`, or `opus` alone), providing the automated coverage that makes the manual smoke pass structurally guaranteed."
