---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L112-L130
  - docs/qrspi/2026-05-17-v07-release/design.md:L196-L246
artifact: plan
round: 2
reviewer: goal-traceability-claude
---

G4 Path B (cache_control marker insertion) is a design-level commitment with no implementing task in the plan.

Design.md G4 Mechanism A explicitly states: "If the dispatch path does NOT cache automatically (to be verified during the Plan-time spike), Mechanism A on this surface also includes adding the caching mechanism at the Anthropic SDK boundary (including Anthropic-style cache_control markers on stable prefixes) BEFORE the measurement step. G4 scope expands accordingly." The design further states: "if no cache metadata is exposed (or hit rate is zero on identical prefixes), G4 scope expands to add cache_control markers at the Anthropic SDK boundary; Plan authors that as a separate task."

The plan does not author that task. T33 authors the probe script and spike report. T36 has path-conditional BATS fixtures that branch on the spike report's Path A or Path B decision. But no task in the plan implements the cache_control marker insertion that design.md says G4 scope expands to include when Path B is active. If T33's probe determines Path B (no automatic caching), the plan has no task to execute and Phase 1 cannot satisfy the G4 Mechanism A contract on that path.

The Slice 7 Phase 1 acceptance block (plan.md lines ~112-130) makes no mention of the Path B contingent scope — it only has the written deliverable bullet, the recorded decision bullet, and the summary-shim rejection pin bullet. There is no acceptance criterion gating on "if Path B, cache_control markers added and verified."

This is a forward-trace gap: G4's design commitment (scope expands if measurement requires) has no covering task or plan-authored acceptance criterion for the expansion path. Every goal's coverage must have at least one plan-authored test expectation; the Path B scenario has none.

**Fix:** Either (a) add a contingent task (T33b or similar) with frontmatter `goal_ids: [G4]` and test expectations covering cache_control marker insertion and hit-rate measurement after insertion — declared conditional on the T33 spike reporting Path B — or (b) explicitly declare that Path B work is deferred to a follow-up release and record that deferral in the plan with a named deferral bullet in the Slice 7 acceptance block so the replan gate knows to expect no Path B implementation in Phase 1. Option (b) is also valid if the design supports it; what is not valid is leaving the contingency unaddressed.
