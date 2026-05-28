---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L272-L278
  - docs/qrspi/2026-05-17-v07-release/plan.md:L332
artifact: plan
round: 4
reviewer: silent-failure-claude
---

T05's test expectations and T07's pin specify what the citation-density validator does when a trusted-model re-run also produces below-floor density: "the validator emits a loud diagnostic naming the below-floor density value and does not silently forward the below-floor output." This is a "does not silently X" statement — it names the wrong behavior (silent forwarding) and says it won't happen, but does NOT specify what the validator does instead (the correct behavior).

The silent-failure gap: the caller — the Implement skill's specialist dispatch prose — receives no defined signal. "Emits a loud diagnostic" describes what is logged, not what the dispatch site sees as its return code or stop condition. An implementer can satisfy "does not silently forward" by logging a warning and then returning exit 0 with the below-floor output discarded (returning empty content), which is a different form of silent failure: the caller gets exit 0 with no content and cannot distinguish "trusted re-run also below-floor" from "upstream error" or "empty response."

T05's description (L268) says: "the validator emits a loud diagnostic naming the below-floor density value and does not silently forward the below-floor output to downstream consumers — the second-below-floor outcome is observably distinct from the success path." The phrase "observably distinct from the success path" is the right intent but the distinction is not defined: is the second-below-floor outcome: (a) a non-zero exit code from the validator that Implement must handle as a task failure, (b) a paused orchestrator state that surfaces to the user, or (c) something else? T07's test coverage (L332) says only "the validator emits a loud diagnostic naming the below-floor density value and does not silently forward the output" — it doesn't add an exit-code or caller-signal requirement.

This means at runtime an implementer could write a validator that logs a warning and exits 0 with an empty result body, satisfying all three stated requirements: (1) loud diagnostic emitted — yes; (2) does not silently forward the below-floor output — yes, it forwarded nothing; (3) "observably distinct from success" — arguably yes if the output is empty. But the Implement skill's downstream action (use the specialist output for a design decision) receives an empty body with no error signal, silently degrading the research quality.

**Fix:** Add a test expectation to T05 and T07 that specifies the exact caller-visible signal for the second-below-floor path. The minimal specification is: "when the trusted-model re-run also produces below-floor citation density, the validator exits non-zero (propagating a failure signal to the Implement orchestrator) so the Implement skill can distinguish the second-below-floor failure from a successful dispatch, rather than treating a zero-exit empty body as a success-path specialist output." Without this signal, the Implement skill has no basis to decide between "retry on a different topic angle," "escalate to opus," or "proceed with degraded output."
