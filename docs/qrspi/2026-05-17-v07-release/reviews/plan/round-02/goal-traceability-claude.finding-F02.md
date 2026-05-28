---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L115-L129
  - docs/qrspi/2026-05-17-v07-release/design.md:L208-L238
artifact: plan
round: 2
reviewer: goal-traceability-claude
---

Slice 7 Phase 1 acceptance block is missing a criterion for G4 Mechanism B (section-anchor indexes + narrow Reads).

The Slice 7 acceptance block in plan.md has three bullets:
1. A written deliverable records hit-rate behavior (Mechanism A spike).
2. A recorded decision determines whether caching is sufficient (Mechanism A spike outcome).
3. The summary-shim rejection invariant pin runs green (T37 cross-cutting invariant).

None of these covers Mechanism B (the section-anchor index delivered by T34-T35). Design.md G4 test strategy explicitly requires: "For narrow Reads, verify that agents using the section-anchor index Read only the expected line ranges and that the assembled content is byte-identical to the corresponding source slice." T34 and T35 deliver the three initial `.anchors.json` index files and the refresh script. T36's `test-section-anchor-narrow-read.bats` and `test-section-anchor-index-shape.bats` pins verify the index correctness and byte-identical slice contract at the task level.

However, the Phase 1 replan gate for Slice 7 can be satisfied without any Mechanism B delivery being correct. A reviewer at replan time looking only at the acceptance block would see the spike deliverable and the summary-shim pin but nothing asserting that the section-anchor indexes exist, are well-formed, and support byte-identical narrow reads. The three Mechanism B files (reviewer-protocol, using-qrspi, plan SKILL.anchors.json) plus the manifest are distinct deliverables from the spike and deserve at least one acceptance criterion in the replan gate.

Design.md treats both mechanisms as unconditional ships ("Mechanism B ships unconditionally in v0.7 independent of the T33 spike outcome"). Since Mechanism B is unconditional, its acceptance criterion belongs in the replan gate alongside the spike.

**Fix:** Add one acceptance bullet to the Slice 7 acceptance block (and to the matching Phase 1 acceptance block in plan.md) covering Mechanism B's delivery: "The three colocated section-anchor index files (`skills/reviewer-protocol/SKILL.anchors.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/plan/SKILL.anchors.json`) and the manifest exist and are verified by the `test-section-anchor-index-shape.bats` and `test-section-anchor-narrow-read.bats` pins running green." This matches what design.md commits to for G4 Mechanism B.
