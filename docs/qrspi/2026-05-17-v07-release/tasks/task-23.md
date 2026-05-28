---
task: 23
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G8, G9, G14]
dependencies: [T13, T20, T21]
loc_estimate: 120
---

# Task 23: New Slice 4 pins — parallelize owns-defers and canonical vocabulary

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-parallelize-owns-defers.bats` (Create) — pin that asserts the OWNS list in `skills/parallelize/owns-defers.md` contains the Worktree-Aware Setup Validation entry added in T20, using the shared `skill-markdown.bash` helper for section extraction.
  - `tests/unit/test-parallelize-vocab.bats` (Create) — pin that asserts the canonical multi-stage suffix-grammar tokens are present in both `skills/parallelize/SKILL.md`'s Branch Model section and `agents/qrspi-parallelize-reviewer.md`'s vocabulary list, plus a drift-fixture assertion that an unconventional form (`stageAfterWave4`) is flagged.
- **Dependencies:** T13, T20, T21
- **LOC estimate:** ~120
- **Description:** Lands the two Slice 4 contract pins that observe the post-T20 and post-T21 surfaces and prevent future drift. `tests/unit/test-parallelize-owns-defers.bats` consumes the shared `tests/helpers/skill-markdown.bash` helper to extract the OWNS H2/H3 section from `skills/parallelize/owns-defers.md` and asserts that the extract contains a Worktree-Aware Setup Validation line scoped as advisory (no auto-patch); a separate assertion confirms the DEFERS section retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned. `tests/unit/test-parallelize-vocab.bats` uses the same helper to extract the Branch Model section from `skills/parallelize/SKILL.md` and the vocabulary-expectation section from `agents/qrspi-parallelize-reviewer.md`, then asserts that the canonical token set (`feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form) is present in both files with no drift between the two; a final assertion uses a drift fixture containing the unconventional form `stageAfterWave4` and verifies the reviewer-side regex flags it as a style violation. Both pins follow the loud-failure contract from the helper so missing-anchor or empty-extract conditions surface as named diagnostics rather than silent passes.
- **Test expectations:**
  - `test-parallelize-owns-defers.bats` extracts the OWNS section from `skills/parallelize/owns-defers.md` via the helper and asserts a Worktree-Aware Setup Validation entry is present.
  - The same file asserts the OWNS entry names the advisory-only scope and does not declare an auto-patch responsibility.
  - The same file asserts the DEFERS section retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned.
  - `test-parallelize-vocab.bats` extracts the Branch Model section from `skills/parallelize/SKILL.md` via the helper and asserts the canonical tokens `feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form are present.
  - The same file extracts the vocabulary-expectation section from `agents/qrspi-parallelize-reviewer.md` via the helper and asserts the same canonical token set is present.
  - The same file asserts no drift exists between the SKILL.md canonical tokens and the reviewer file's accepted-token list.
  - The same file uses a drift fixture containing `stageAfterWave4` and asserts the reviewer-side flag fires on the unconventional form.
  - Both pins emit the helper's loud-failure diagnostic (file, heading anchor, miss reason) when a section anchor is missing or the extract is empty, rather than silently passing.
