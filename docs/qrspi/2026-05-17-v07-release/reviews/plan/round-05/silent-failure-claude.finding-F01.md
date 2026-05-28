---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L329
artifact: plan
round: 5
reviewer: silent-failure-claude
---

T07's description (L329) states `test-citation-density-validator.bats` "exercises the below-floor case (exactly one trusted re-run), the above-floor case (no re-run, output proceeds), and the `0.05` floor default when `validators.citation_density_floor:` is absent." The description omits the second-below-floor outcome (the case where the trusted-model re-run also produces below-floor density) that T07's test expectations explicitly require at L334: "the validator emits a loud diagnostic naming the below-floor density value, exits non-zero so the Implement orchestrator observes a specialist-dispatch failure signal, and does not silently forward the output — the pin asserts the non-zero exit so a regression to zero-exit-with-empty-body is caught."

The silent-failure risk is implementation-order: the task description is the implementer's first read. An implementer reading L329's description would author `test-citation-density-validator.bats` with three cases (below-floor one-rerun, above-floor, default floor) and miss the fourth required case (second-below-floor non-zero exit). The test expectations at L334 do specify it, but the description/expectations mismatch means an implementer authoring T07 from the description alone writes an incomplete pin.

This is the same class as R4-F01 (stale residue in the description after the R4 fix to T05 and T07 test expectations added the second-below-floor exit-code requirement). R4-F02 fixed the T05 test expectation and T07 test expectation to specify "exits non-zero," but the T07 *description* still lists only three test cases for the citation-density validator pin, leaving the fourth case implied but not stated.

**Fix:** Add "and the second-below-floor case (trusted-model re-run also below-floor: exits non-zero with a loud diagnostic, no forward)" to T07's description of what `test-citation-density-validator.bats` exercises, matching the test expectation already present at L334.
