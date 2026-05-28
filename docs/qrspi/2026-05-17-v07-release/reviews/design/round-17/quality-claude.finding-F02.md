---
finding_id: R17-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1143, docs/qrspi/2026-05-17-v07-release/design.md:L1212, docs/qrspi/2026-05-17-v07-release/design.md:L296]
artifact: design
round: 17
reviewer: quality-claude
---

The cross-cutting test strategy and the per-goal summary table both omit the "absent `task_type:` defaults to TDD path" case for G6, creating an internal inconsistency with the G6 recommendation body.

G6's recommendation body (design.md line 296) explicitly states the split is "Universal for `task_type: code` (or absence of `task_type:`, which defaults to the TDD path)." This establishes that a task with no `task_type:` field is treated as a TDD task and receives the two-dispatch split.

However:

1. The cross-cutting TDD test strategy (line 1143) says: "A task with `task_type: code` causes two dispatches: test-writer first, then implementer." It does NOT mention the absent-`task_type` case.
2. The per-goal test expectations table (line 1212) for G6 reads "Per-task dispatch shape for `task_type: code` and `lightweight`" — again omitting absent `task_type`.

A Plan or Implement author relying on the cross-cutting section or the summary table would author test cases and implementation only for the explicit `task_type: code` value, leaving the default case unverified. If the orchestrator only branches on the explicit string `code` and does not handle the absent-field case, tasks with no `task_type:` field (which the task-spec template shows default to the TDD path) would bypass the test-writer split.

Fix: add the absent-`task_type` case to the cross-cutting TDD test strategy bullet and to the per-goal test table description, so all three locations agree. For example, update line 1143 to: "A task with `task_type: code` or with no `task_type:` field causes two dispatches: test-writer first, then implementer."
