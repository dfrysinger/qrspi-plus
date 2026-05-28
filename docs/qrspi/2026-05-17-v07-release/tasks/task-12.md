---
task: 12
status: approved
pipeline: full
task_type: lightweight
model: opus
phase: 1
goal_ids: [G6]
dependencies: [T11]
loc_estimate: 80
---

# Task 12: Plan-skill per-task dispatch-order note + task_type defaulting

- **Phase:** 1
- **Target files:**
  - `skills/plan/SKILL.md` (Modify) — extend the per-task spec template so TDD tasks emit a dispatch-ordering note (test-writer first, implementer second) and add the `task_type:` defaulting note that absent `task_type:` defaults to the TDD path (test-writer plus implementer), `task_type: code` follows the same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch.
- **Dependencies:** T11
- **LOC estimate:** ~80
- **Description:** Extends `skills/plan/SKILL.md`'s per-task spec template so generated `tasks/task-NN.md` files for TDD tasks carry an explicit dispatch-ordering note that the test-writer dispatches before the implementer, matching the orchestration landed by T11. The same edit documents the `task_type:` defaulting rule: absent `task_type:` defaults to the TDD path (test-writer dispatch followed by implementer dispatch through the RED-verification gate), `task_type: code` follows that same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch with no test-writer and no RED gate. The defaulting note lives in the per-task spec template section so every future task spec the Plan skill emits inherits the convention without per-task re-authoring. The edit is scoped to the per-task spec template and the `task_type:` field documentation; it does not modify the post-approval split orchestration owned by Slice 6.
- **Test expectations:**
  - The per-task spec template in `skills/plan/SKILL.md` emits a dispatch-ordering note (test-writer first, implementer second) for TDD tasks.
  - The `task_type:` documentation states that absent `task_type:` defaults to the TDD path.
  - The `task_type:` documentation states that `task_type: code` follows the TDD path.
  - The `task_type:` documentation states that `task_type: lightweight` produces the lightweight-only dispatch (no test-writer, no RED gate).
  - The edit is confined to the per-task spec template and `task_type:` field documentation (no changes to post-approval split orchestration).
