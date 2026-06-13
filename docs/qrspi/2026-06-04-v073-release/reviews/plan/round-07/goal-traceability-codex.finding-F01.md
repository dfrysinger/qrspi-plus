---
finding_id: R7-F01
severity: medium
change_type: correctness
referenced_files:
  - plan.md:L573-L577
  - plan.md:L583-L584
  - design.md:L319-L320
  - design.md:L386-L387
  - structure.md:L88-L89
  - structure.md:L352-L354
artifact: plan
round: 7
reviewer: goal-traceability-codex
---

Spec-to-design/structure fidelity inconsistent on OBC exit-code contract. Plan (T19) and design (d3fff0d amendment) require `scripts/orchestration-boundary-check.sh` to exit non-zero when `## Dispatch defects` is non-empty, but structure.md still specifies "exit 0 always (fail-soft)." Two conflicting authoritative contracts for the same interface. Resolve by aligning structure.md's OBC contract to the design/plan fail-loud-on-dispatch-defects behavior.

Note: This is a structure-phase contract drift created by the d3fff0d design.md amendment. Per `skills/plan/owns-defers.md` § Upstream-contract deferrals, fixing structure.md requires a Structure-phase amendment. Plan-side fix is an Author Note pointing to the resolution.
