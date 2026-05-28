---
finding_id: R1-F08
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T25's test expectations check for a Red Flags entry but don't verify the Structure skill's refusal behavior, leaving the enforcement contract untestable.

T25's test expectation reads: "A Red Flags entry fires when a plan contains lift_source: tasks but structure.md lacks the section."

"A Red Flags entry fires" is not a behavioral test — it's a documentation assertion (the Red Flags table contains the entry). The design's G11 test strategy (design.md line 622) states: "Structure-section test: when the plan contains any lift_source: task, structure.md contains a ## UI Reference Affordances section." And T25's description says: "Structure refuses to mark structure.md approved if a lift_source: task exists in the plan without a corresponding ## UI Reference Affordances section."

The behavioral test should assert that the Structure skill actually refuses approval, not just that the Red Flags table mentions the condition. An observable test would be: "When a fixture plan.md contains a task with lift_source: but structure.md is missing the ## UI Reference Affordances section, the Structure skill returns a named failure/refusal rather than marking status: approved."

As written, T25's test expectation would pass if the Red Flags entry is present in the prose but the skill's approval step is missing the guard entirely. Add a behavioral test expectation covering the actual refusal outcome — what the caller observes when the guard fires.
