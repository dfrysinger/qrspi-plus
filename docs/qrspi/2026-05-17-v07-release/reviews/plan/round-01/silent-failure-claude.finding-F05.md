---
finding_id: R1-F05
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L253-L257]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T05's test expectations include "The telemetry prose states that absence of the telemetry file at task-DONE time is a loud failure, not a silent skip." This is explicitly correct and closes the silent-failure path for the telemetry file itself. However, T05 also describes the citation-density validator for the research specialist: "below-floor citation-density triggers exactly one re-run on the trusted model; above-floor proceeds."

The test expectations for T05 state: "The specialist dispatch prose specifies that below-floor citation-density triggers exactly one re-run on the trusted model and that above-floor output proceeds unchanged." But no test expectation specifies what happens when the re-run also produces below-floor citation density. The "exactly one re-run" constraint means there is no third attempt, but the test expectations do not specify whether a second below-floor result: (a) proceeds anyway (silent fallback — the below-floor output silently goes to the downstream consumer), (b) produces a loud failure that halts dispatch, or (c) triggers a human-gate pause.

If option (a) is what gets implemented, then a research-specialist output that fails citation-density on both the cheap model AND the trusted model proceeds to downstream Design decisions with a below-floor citation density — a silent quality failure. The "exactly one re-run" constraint is meaningless if the re-run's result is consumed regardless of its quality.

T07's `test-citation-density-validator.bats` test expectations only cover "the below-floor case (exactly one trusted re-run), the above-floor case (no re-run, output proceeds), and the `0.05` floor default." There is no test expectation for what the validator does when the trusted-model re-run also produces below-floor density.

The fix is to add a test expectation in T05 or T07: "When the trusted-model re-run after a below-floor result also produces below-floor citation density, the validator emits a loud diagnostic naming the below-floor density value and does not silently forward the below-floor output to downstream consumers." The caller must know the output is still below floor even after the re-run.
