---
task: 21
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G9]
dependencies: []
loc_estimate: 90
---

# Task 21: Align multi-stage suffix grammar in parallelize SKILL.md and parallelize-reviewer agent

- **Phase:** 1
- **Target files:**
  - `skills/parallelize/SKILL.md` (Modify) — document the canonical multi-stage suffix grammar `stage-after-W{N}{suffix}` (suffix `a|b|c|...`) inside the Branch Model section and extend the Worked Example to cover a multi-stage-per-Wave case.
  - `agents/qrspi-parallelize-reviewer.md` (Modify) — align the reviewer's vocabulary-expectation list with the canonical tokens in `skills/parallelize/SKILL.md` so canonical forms are not flagged as style violations.
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** Resolves the Parallelize-reviewer false-positive class caused by vocabulary drift between the skill's Branch Map prose and the reviewer's accepted-token list. Updates `skills/parallelize/SKILL.md`'s Branch Model section to declare the canonical multi-stage suffix grammar `stage-after-W{N}{suffix}` where `{N}` is the originating Wave index and `{suffix}` is a single lowercase letter (`a`, `b`, `c`, ...) ordering multiple stages emitted from the same Wave; the existing Worked Example is extended to cover a Wave that emits multiple stage branches so the suffixed form has a documented illustration. The companion edit in `agents/qrspi-parallelize-reviewer.md` aligns the reviewer's accepted-vocabulary list to the same canonical tokens (`feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form) and removes the rejected non-canonical forms (hyphenated or integer-suffixed variants) that were producing style findings on valid artifacts. The skill is the source of truth; the reviewer file is brought into line with the skill.
- **Test expectations:**
  - The Branch Model section in `skills/parallelize/SKILL.md` documents the `stage-after-W{N}{suffix}` form and names the suffix alphabet (`a|b|c|...`).
  - The Worked Example in `skills/parallelize/SKILL.md` illustrates at least one Wave emitting multiple stage branches using the suffixed form.
  - The vocabulary-expectation list in `agents/qrspi-parallelize-reviewer.md` enumerates the canonical tokens `feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed variant.
  - The reviewer file no longer enumerates the previously rejected non-canonical forms as acceptable variants.
  - The reviewer's accepted-token list matches the SKILL.md canonical token set with no drift between the two files.
  - (Phase-acceptance — Integrate-time, not a BATS unit pin): re-dispatching the Parallelize quality reviewer against a parallelization artifact that uses the canonical multi-stage suffix grammar produces no style finding; an artificially-introduced unconventional form (e.g., `stageAfterWave4`) still produces a style finding. Deterministic unit-tier observation lives in T23's `test-parallelize-vocab.bats`.
