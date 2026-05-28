---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L138
  - docs/qrspi/2026-05-17-v07-release/plan.md:L967-L973
  - docs/qrspi/2026-05-17-v07-release/plan.md:L992-L1002
artifact: plan
round: 4
reviewer: spec-claude
---

The `## Task Specs` preamble at plan.md line 138 states: "The Plan post-approval split sub-subagent (T31) preserves both fields verbatim when emitting per-task spec files." Neither T31's test expectations (lines 967–973) nor T32's BATS pin test expectations (lines 992–1002) assert this preservation.

T31's last test expectation (line 973) enumerates the spec frontmatter fields the canonical task-file template must carry — `reference_gate:`, `reference_artifact:`, `ui:`, `lift_source:` (the T24 fields) — but the two new conditional fields (`conditional:` and `conditional_precondition:`) are absent from that list. T32's test expectations cover N-threshold branching, atomicity, and exact-set verification, but include no assertion that a sub-subagent emitting a conditional task preserves `conditional: true` and `conditional_precondition:` verbatim in the output `tasks/task-NN.md` file.

If a sub-subagent strips or omits these fields during the fan-out, T43 would be dispatched unconditionally at Implement time (since the Implement orchestrator reads `conditional: true` from the emitted per-task file — which would now lack the field). The preamble declares the preservation requirement, but without a test expectation or BATS pin asserting it, the implementer has no clear signal to validate this behavior and the reviewer has no observable criterion to check.

**Resolution:** Add one test expectation to T31 (after the current line-973 bullet) stating that when a task spec carries `conditional: true` and `conditional_precondition:`, the sub-subagent payload template includes both fields and the emitted `tasks/task-NN.md` file carries both fields verbatim. Add one corresponding BATS assertion to T32's pin test expectations: a fixture fan-out on a plan containing T43's conditional fields produces a `tasks/task-43.md` file (or the fixture equivalent) whose frontmatter contains `conditional: true` and the correct `conditional_precondition:` value unchanged.
