---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L106-L113
  - docs/qrspi/2026-05-17-v07-release/design.md:L590-L626
artifact: plan
round: 2
reviewer: goal-traceability-claude
---

Slice 5 Phase 1 acceptance block is missing a criterion for the G11 quick-tier finding-disposition wording clarification.

The three Slice 5 acceptance bullets in plan.md cover:
1. A human gate for a UI-producing task surfaces visual reference in a renderable form.
2. A reference-gated UI task pauses dependents until approval is recorded.
3. The visual-fidelity reviewer's output for a UI task dispatched alongside sibling UI tasks references sibling findings or states no relevant sibling context was found.

G11 (Apply Keeplii harness lessons) also explicitly includes the quick-tier review wording clarification: "Quick-tier review wording may need clarification: the observed useful pattern was inline-patch high and correctness-medium findings while accepting lows, not blindly merge or escalate every quick-tier task." Design.md G11 recommendation section includes "Quick-tier review wording clarification (ships independently). Update `skills/reviewer-protocol/SKILL.md` quick-tier guidance." Design.md G11 test strategy includes "Quick-tier wording test: `skills/reviewer-protocol/SKILL.md` contains the codified quick-tier patch-vs-accept guidance."

T29 implements this (modifying `skills/reviewer-protocol/SKILL.md` to add quick-tier finding-disposition guidance) and T30's pin four asserts it (the `test-quick-tier-wording.bats` pin). But the Slice 5 replan gate has no criterion covering this G11 deliverable. A replan reviewer looking at the acceptance block would see the human-gate and visual-fidelity criteria but nothing requiring the quick-tier wording to exist in the reviewer-protocol skill. T29 could be skipped or broken and the Slice 5 acceptance block would still pass.

The quick-tier wording clarification is stated in design.md as an independent ship within Slice 5 ("ships independently" per design.md) and is load-bearing for G11's traceability. It needs a criterion in the replan gate.

**Fix:** Add one acceptance bullet to the Slice 5 acceptance block: "The quick-tier finding-disposition guidance (`skills/reviewer-protocol/SKILL.md`) codifies inline-patch for high and correctness-medium findings, acceptance for low findings, and prohibition of blanket quick-tier merges — observable via the `test-quick-tier-wording.bats` pin running green under the unit BATS surface." This closes the G11 quick-tier coverage gap in the replan gate.
