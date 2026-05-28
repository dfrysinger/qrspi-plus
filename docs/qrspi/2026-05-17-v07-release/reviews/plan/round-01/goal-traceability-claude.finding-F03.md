---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md
  - docs/qrspi/2026-05-17-v07-release/design.md
artifact: plan
round: 1
reviewer: goal-traceability-claude
---

The Phase 1 acceptance criteria block for Slice 7 (G4 — Context optimization) is incomplete: it covers the caching spike/measurement deliverable but omits an observable criterion for the summary-shim rejection invariant that T37 delivers.

The Slice 7 acceptance block currently reads:

- "A written deliverable records the hit-rate behavior of representative high-token-cost dispatches against stable prefixes, observable as a release artifact."
- "A recorded decision determines whether the platform's existing caching behavior is sufficient or whether follow-up implementation is required; downstream implementation work is either green-lit by the measurement or scoped against the gap the measurement surfaced."

T37 ships `tests/unit/test-no-summary-shim-dispatches.bats` — a cross-cutting pin that enforces design.md's explicit rejection of summary shims ("Explicitly rejected — summary shims" in design.md §G4). The design calls this out as a load-bearing invariant: "For the rejection of summary shims, the test is a code search that confirms no agent dispatch site is feeding LLM-generated summaries of stable artifacts back into prompts as source-of-truth." T37's test expectation block states the test must run green against the current dispatch surface.

Per the strip-from-goals contract, plan.md authors the acceptance criteria. The per-phase acceptance block should include an observable criterion covering T37's invariant — otherwise the Slice 7 acceptance block appears to close when only the spike measurement lands, even if the summary-shim pin is missing or failing.

G4's goal problem framing explicitly identifies summary shims as a candidate that Design must evaluate. Design rejected them. The plan must make that rejection observable at phase acceptance.

Resolution: add a third bullet to the Slice 7 Phase 1 acceptance block, for example: "The summary-shim rejection invariant pin (`test-no-summary-shim-dispatches.bats`) runs green under the unit BATS surface, asserting no agent dispatch site substitutes an LLM-generated condensation of a stable artifact as the prompt's source-of-truth payload."
