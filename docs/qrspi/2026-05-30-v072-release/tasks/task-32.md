---
status: approved
task: 32
phase: 1
pipeline: full
goal_ids: [G30]
task_type: code
model: opus
---

# Task 32: G30 Goals and Design dialogue authoring quality and compaction-resilient incremental persistence

- **Target files:** modify `skills/goals/SKILL.md`, modify `skills/design/SKILL.md`, modify `tests/unit/test-interactive-skill-prompts.bats`
- **Dependencies:** Task 30, Task 31
- **LOC estimate:** ~180

**Overview**

Make Goals and Design persist each locked decision directly into their final draft artifact, survive compaction by resuming from that artifact, and finalize only after completeness validation; add the approved Goals dialogue-conduct subset so both interactive phases ask grounded, one-at-a-time questions. (Why: see goals.md ### G30. Approach: see design.md ## G30, design.md ## G1, and design.md ## G33.)

**Scope**

- **In:**
  - Update `skills/design/SKILL.md` so each per-decision lock writes directly to `design.md` with `status: draft`, using the Task 30 five-field per-goal template and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.
  - Update `skills/goals/SKILL.md` so each locked goal writes directly to `goals.md` with `status: draft`, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.
  - Add the Goals dialogue-conduct subset: Rules 1, 2, 4, 6, 7, and 8 match the Design wording; Rule 3 uses Goals-safe grounding order of codebase then web; Rule 5's simple-language directive remains absent from Goals.
  - Document presence-as-locked semantics in both skills: tentative, placeholder, `to be filled`, TODO, or similar incomplete decision bodies never enter draft artifacts; re-locking an existing decision overwrites that keyed block in place instead of appending a duplicate.
  - Document resume-after-compaction behavior in both skills: re-read the draft artifact, enumerate locked decisions, surface the exact diagnostic `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`, then continue from the next unlocked decision.
  - Document the skill-specific remaining-work rule: Goals asks the user whether all desired goals have been articulated; Design computes remaining work from `goals.md` goals minus locked per-goal blocks in `design.md`.
  - Document end-of-phase finalize behavior: Goals validates locked goal completeness, optionally appends Purpose if absent, and flips `status: draft` to `approved`; Design validates every `goals.md` goal has all five fields populated, validates Cross-Goal Decisions well-formedness, and flips `status: draft` to `approved-pending-review`.
  - Update `tests/unit/test-interactive-skill-prompts.bats` to pin the dialogue-conduct, incremental-write, lock-semantics, resume, finalize, and simulated-compaction contracts above.

- **Out:**
  - Creating the CD-3 Multi-Actor Flow Check shared snippet and downstream include sites — T28 owns.
  - Authoring the Design five-field per-goal template, Dialogue Conduct base section, and altitude sub-rules — T30 owns; this task consumes those established contracts.
  - Authoring or broadening the Design-only simple-language Rule 5 — T31 owns; this task only preserves the Goals absence contract while using the approved Design wording as the comparison source.
  - Updating reviewer-agent files to enforce draft-artifact status or placeholder checks — not in this task's target files.

**Definition of done**

- `skills/design/SKILL.md` instructs direct incremental writes to `design.md` with `status: draft` after each per-decision lock signal, including the Task 30 five-field template and `## Cross-Goal Decisions` handling.
- `skills/goals/SKILL.md` instructs direct incremental writes to `goals.md` with `status: draft` as goals lock, while preserving the existing Goals template, question-topic checklist, and Pipeline Mode Selection step.
- Goals dialogue conduct mirrors Design Rules 1, 2, 4, 6, 7, and 8; Rule 3 uses codebase → web grounding; the Rule 5 simple-language directive is absent from Goals.
- Both skills define presence-as-locked semantics, prohibit placeholder or tentative draft blocks, and require keyed overwrite on re-lock instead of duplicate append.
- Both skills define resume-after-compaction using the exact diagnostic string and the correct remaining-work computation for that skill.
- Both skills define finalize validation and status transition behavior exactly as scoped: Goals to `approved`; Design to `approved-pending-review`.
- `tests/unit/test-interactive-skill-prompts.bats` covers the Goals conduct subset, Design and Goals incremental-write behavior, placeholder prohibition, resume diagnostic, remaining-work split, finalize pass, and simulated-compaction durability contract.

**Test expectations**

- `tests/unit/test-interactive-skill-prompts.bats` fails before implementation and passes after it pins the Goals dialogue-conduct subset: Rules 1, 2, 4, 6, 7, and 8 match Design wording; Rule 3 uses codebase → web grounding; Rule 5's simple-language directive remains absent from Goals.
- Tests pin `skills/design/SKILL.md` behavior for direct incremental writes to `design.md` with `status: draft` after each per-decision lock signal, using the five-field per-goal template from Task 30 and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.
- Tests pin `skills/goals/SKILL.md` behavior for direct incremental writes to `goals.md` with `status: draft` as goals lock, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.
- Grep or assertion coverage verifies both skills document presence-as-locked semantics, reject tentative / placeholder / `to be filled` / TODO-like decision bodies in draft artifacts, and require keyed in-place overwrite when a decision is re-locked.
- Tests pin the exact resume diagnostic string: `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`.
- Tests distinguish remaining-work computation: Goals asks the user whether all desired goals have been articulated; Design computes remaining work from `goals.md` goals minus locked per-goal blocks in `design.md`.
- Tests pin the finalize pass: Goals validates locked goal completeness, optionally appends Purpose if absent, and flips `status: draft` to `approved`; Design validates all five fields for every goal, validates Cross-Goal Decisions well-formedness, and flips `status: draft` to `approved-pending-review`.
- Simulated-compaction coverage uses a mid-phase decision such as G15 and verifies resume produces the same final artifact content as a no-compaction run.

**References**

- goals.md ### G30 — problem framing for Goals/Design dialogue quality gaps and compaction-loss risk.
- design.md ## G30 — direct-to-artifact draft persistence, lock semantics, resume diagnostic, finalize behavior, and acceptance criteria.
- design.md ## G1 — Design five-field template and base Dialogue Conduct rules consumed by this task.
- design.md ## G33 — Design-only simple-language Rule 5 that must remain absent from Goals.
- structure.md ### `skills/design/SKILL.md` — Slice 1.5 G30 per-file block for Design incremental persistence and tests.
- structure.md ### `skills/goals/SKILL.md` — Slice 1.5 G30 per-file block for Goals dialogue-conduct subset and incremental persistence.
- structure.md ### `tests/unit/test-interactive-skill-prompts.bats` — test block pinning dialogue conduct, resume diagnostics, and simulated-compaction durability.
