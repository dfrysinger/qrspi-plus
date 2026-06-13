---
status: approved
task: 17
phase: 1
pipeline: full
goal_ids: [G3]
task_type: tdd
tier: medium
---

# Task 17a: Create tests/unit/test-plan-spec-reviewer-absorption.bats

- **Target files:** `tests/unit/test-plan-spec-reviewer-absorption.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~30
- **Description:** A synthetic-dispatch bats test verifies the T16 plan-spec rubric clause fires on real findings. The test drafts a fixture `plan.md` with a task labeled with an absorbed goal ID (per a fixture absorption-map produced by T02's script) and asserts the plan-spec reviewer produces a `change_type: scope` finding. The test also invokes the Plan-step plan-spec-reviewer dispatch with the `absorption_map_path:` parameter absent and asserts the reviewer halts non-zero with the `dispatch-defect:` named diagnostic instead of silently proceeding with an empty absorbed-ID set (silent-claude R2-F02 fail-loud direction at the Plan step).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic plan.md drafted with an absorbed-ID task produces a `change_type: scope` finding from the plan-spec reviewer (Acceptance bullet 4, second half).
  - A clean plan.md fixture (no absorbed-ID tasks) produces zero absorption findings (no-false-positive guard).
  - A Plan-step plan-spec-reviewer dispatch with `absorption_map_path:` absent halts the reviewer with a `dispatch-defect:` named diagnostic and non-zero exit — the reviewer does not silently produce a zero-finding pass (silent-claude R2-F02 fail-loud direction).
