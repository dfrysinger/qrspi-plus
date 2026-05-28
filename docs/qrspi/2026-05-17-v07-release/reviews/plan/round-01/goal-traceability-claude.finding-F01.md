---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md
  - docs/qrspi/2026-05-17-v07-release/goals.md
  - docs/qrspi/2026-05-17-v07-release/design.md
artifact: plan
round: 1
reviewer: goal-traceability-claude
---

G5 (Dispatcher tolerance research) requires producing a populated initial routing matrix — a table mapping each dispatcher class to its initial routing decision — as its primary deliverable. The design.md §G5 section explicitly authors this matrix:

| Dispatcher class | Initial routing | Reasoning |
|---|---|---|
| `qrspi-research-collator` | Cheap-model eligible | ... |
| `qrspi-implementer-lightweight` | Cheap-model eligible | ... |
| `qrspi-research-specialist` | Cheap-model eligible (with post-output citation-density validation) | ... |
| General-purpose / Explore | Conditional. Trusted path by default... | ... |
| `qrspi-test-writer` | Cheap-model eligible (both modes) | ... |

No task in Slice 1 (T01–T07) is explicitly assigned ownership of authoring or documenting this matrix. The tasks produce the routing infrastructure (T01 schema, T02 library, T03 dispatcher, T04 shim retirement, T05 routing chain + telemetry, T06 agent frontmatter) and BATS pins (T07). T07's `test-routing-matrix-application.bats` description says it "pins initial-matrix dispatch decisions per dispatcher class" — but no preceding task description names "author the initial routing matrix" as a deliverable. The matrix content is design-level; the plan must assign a task to materialize it.

The forward-traceability contract from G5 to plan-authored test expectations breaks here: the G5 acceptance criterion in the Phase 1 block only checks that a non-Anthropic routing site dispatches and records telemetry. It does not verify the populated routing matrix is written or accessible as a documented artifact (in a skill file section, a config default, or a separate reference document). A reader auditing G5 against the plan cannot identify which task's deliverable IS the tolerance matrix.

Resolution: assign ownership of authoring the initial routing matrix to one Slice 1 task (most naturally T05, which authors the routing chain section in `skills/implement/SKILL.md`) by adding a test expectation asserting the matrix table is present in that section. Alternatively, add an explicit matrix document as a target file for T01 or T05. Update the Slice 1 Phase 1 acceptance criterion to reference the matrix as an observable deliverable.
