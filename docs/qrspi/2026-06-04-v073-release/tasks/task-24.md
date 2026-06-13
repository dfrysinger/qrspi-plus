---
status: approved
task: 24
phase: 1
pipeline: full
goal_ids: [G5]
task_type: tdd
tier: low
---

# Task 24: Create tests/lint/test-integrate-test-skill-phase-base-write.bats

- **Target files:** `tests/lint/test-integrate-test-skill-phase-base-write.bats` (Create)
- **Dependencies:** T21, T22
- **LOC estimate:** ~30
- **Description:** A grep audit asserts `skills/integrate/SKILL.md` and `skills/test/SKILL.md` each carry the phase-base.txt write step at phase start — the literal anchor phrases that name `reviews/integration/phase-base.txt` and `reviews/test/phase-base.txt` as the write targets. The lint locks the write side against silent SKILL-prose drift that would break the OBC script's integration/test read paths.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - `skills/integrate/SKILL.md` contains the phase-base.txt write step naming `reviews/integration/phase-base.txt` (anchor-phrase grep) — locks the SKILL prose against the OBC integration read path (G5 Acceptance bullet 4 sub-bullet read-path coverage).
  - `skills/test/SKILL.md` contains the phase-base.txt write step naming `reviews/test/phase-base.txt` (anchor-phrase grep).
  - A fixture skill body missing the write step fails the lint with a named diagnostic identifying which of the two skill files (`skills/integrate/SKILL.md` or `skills/test/SKILL.md`) is missing the write step (named-diagnostic discipline; no opaque `FAIL` output).
