---
task: 26
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T24]
loc_estimate: 90
---

# Task 26: Add Parallelize-skill reference-gate wave termination and parallelization.md note shape

- **Phase:** 1
- **Target files:**
  - `skills/parallelize/SKILL.md` (Modify) — reference-gated task terminates its wave; `parallelization.md` emits an explicit note listing the gate and dependent tasks waiting on it.
- **Dependencies:** T24
- **LOC estimate:** ~90
- **Description:** Extends `skills/parallelize/SKILL.md` so any task carrying T24's `reference_gate: true` frontmatter field acts as a wave-terminating task — no dependent task in any later wave can dispatch until the gate releases. The Parallelize body documents the wave-termination rule alongside the existing wave-grouping logic and updates the Branch Model worked example to show a reference-gated task ending its wave with dependents landing in the next wave. The `parallelization.md` artifact emits an explicit note (canonical shape: `Reference gate: task-NN ({task name}) — dependents waiting: task-XX, task-YY, task-ZZ`) listing every reference-gated task and the dependent task IDs waiting on it; the note shape is documented in the Parallelize template section so reviewers and downstream consumers (T27 Implement) can locate the gates by pattern. Adds a Red Flags entry that fires when `parallelization.md` contains a reference-gated task without the canonical note, or when a dependent of a reference-gated task is scheduled in the same wave as the gate (wave-termination violation). Edits are markdown body and template-spec only, no code; lightweight/sonnet classification holds. Operator may flip to opus before approval if the wave-termination semantics warrant the upgrade.
- **Test expectations:**
  - `skills/parallelize/SKILL.md` documents the wave-termination rule: a task carrying `reference_gate: true` ends its wave and dependents land in the next wave.
  - The Parallelize Branch Model worked example shows a reference-gated task terminating a wave with dependents in the next wave.
  - The Parallelize template section documents the canonical `parallelization.md` note shape naming the gate task and the dependent task IDs waiting on it.
  - A Red Flags entry fires when `parallelization.md` contains a reference-gated task without the canonical note.
  - A Red Flags entry fires when a dependent of a reference-gated task is scheduled in the same wave as the gate.
