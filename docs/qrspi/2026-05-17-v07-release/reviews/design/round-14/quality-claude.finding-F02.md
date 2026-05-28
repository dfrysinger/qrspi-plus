---
finding_id: R14-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/design.md:L562-L569
  - docs/qrspi/2026-05-17-v07-release/design.md:L1019-L1030
artifact: design
round: 14
reviewer: quality-claude
---

The G11 "Reconciliation with existing visual-fidelity affordances" section (around line 566) states: "The new `ui: true` field at task-spec frontmatter **replaces** the nested `visual_fidelity_check.ui_producing` boolean." This is a material change to the existing task-spec schema — a field is being deprecated and removed. However, Decision 10 ("All new task-spec fields are additive and have safe defaults") at line 1019 only lists the four new fields (`reference_gate`, `reference_artifact`, `ui`, `lift_source`) and does not acknowledge that `visual_fidelity_check.ui_producing` is being removed. The exception clause in Decision 10 covers `reference_artifact` being paired with `reference_gate`, but it says nothing about `ui_producing` deprecation.

This creates a contradiction: Decision 10's claim that "A task spec that does not set these fields should behave exactly like a v0.6 task" is not fully true — a v0.6 task spec with `visual_fidelity_check.ui_producing: true` will no longer have the correct signal after v0.7 lands the schema change.

Proposed fix: add a sentence to Decision 10 explicitly noting that `visual_fidelity_check.ui_producing` is deprecated and replaced by `ui: true` at the frontmatter level, and that Plan owns migrating any pre-existing task specs. This reconciles the additive-fields claim with the actual schema change.
