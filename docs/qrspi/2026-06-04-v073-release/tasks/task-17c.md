---
status: approved
task: 17
phase: 1
pipeline: full
goal_ids: [G3]
task_type: tdd
tier: low
---

# Task 17c: Create tests/unit/test-design-reviewer-dispatch-defect.bats

- **Target files:** `tests/unit/test-design-reviewer-dispatch-defect.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~25
- **Description:** A synthetic-dispatch bats test verifies the T16 design-reviewer dispatch-defect contract clause fires on real findings. The test invokes the Design-step reviewer dispatch with the `absorption_map_path:` parameter absent and asserts the reviewer halts non-zero with the `dispatch-defect:` named diagnostic instead of silently no-op'ing.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A Design-step dispatch with `absorption_map_path:` absent halts the design reviewer with a `dispatch-defect:` named diagnostic and non-zero exit (silent-claude F01 dispatch-defect fail-loud direction).
  - A goals/research/phasing/structure/parallelize-step dispatch with `absorption_map_path:` absent proceeds normally (no false positive for steps where the parameter has no applicable role).
