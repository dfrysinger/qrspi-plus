---
status: approved
task: 17
phase: 1
pipeline: full
goal_ids: [G3]
task_type: tdd
tier: low
---

# Task 17b: Create tests/unit/test-design-reviewer-fidelity.bats

- **Target files:** `tests/unit/test-design-reviewer-fidelity.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~25
- **Description:** A synthetic-dispatch bats test verifies the T16 design-reviewer fidelity rubric clause fires on real findings. The test drafts a fixture `design.md` where a goal block's body describes independent scope but the heading suffix claims the goal is absorbed by another CD (intent/marker contradiction), and asserts the design reviewer produces a fidelity-mismatch finding.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic design.md with an intent/marker contradiction produces a fidelity-mismatch finding from the design reviewer (G3 Acceptance bullet 5, second half).
  - A clean design.md fixture (markers consistent with goal-block bodies) produces zero fidelity-mismatch findings (no-false-positive guard).
