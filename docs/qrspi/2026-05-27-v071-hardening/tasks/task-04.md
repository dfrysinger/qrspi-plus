---
status: approved
task: 4
phase: 1
pipeline: full
goal_ids: [G4]
task_type: code
model: opus
---

# Task 4: Reshape parallelize SKILL Branch Map into Wave-grouped sub-sections

- **Target files:** `skills/parallelize/SKILL.md` (modify), `agents/qrspi-parallelize-reviewer.md` (modify), `tests/unit/test-parallelize-vocab.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~120
- **Description:** The Branch Map content in `skills/parallelize/SKILL.md` is reorganized from a flat three-column table into `### Wave N` sub-sections, each containing a Task/Branch/Base mini-table restricted to the tasks belonging to that wave. This restructuring applies to the artifact specification section and to both the "Good" and "Bad" worked-example pairs in the skill. The now-redundant "Execution Order" prose section, which previously described wave groupings in a separate narrative, is removed from both the specification and the worked examples. `agents/qrspi-parallelize-reviewer.md` is updated so its Branch Map structural-rule assertions require `### Wave N` sub-section grouping rather than the former flat three-column layout; the existing symbolic-base vocabulary rule, row-completeness rule, and Dependency Analysis table rules are retained. `tests/unit/test-parallelize-vocab.bats` gains a new assertion pinning the `### Wave N` sub-section structural rule against the reviewer agent, and existing wave-vocabulary assertions are adapted to reference the new sub-section grouping shape. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `skills/parallelize/SKILL.md` contains `### Wave N` sub-section headings (e.g. `### Wave 1`, `### Wave 2`) as the organizing structure for its Branch Map, with no flat three-column Branch Map table appearing outside a Wave sub-section
  - Each `### Wave N` sub-section contains a Markdown table with exactly three columns: Task, Branch, and Base
  - No `## Execution Order` heading or equivalent standalone wave-order prose block exists anywhere in the artifact specification or worked-example sections of the skill
  - The "Good" worked example in the skill shows Wave-grouped sub-sections and matches the updated specification shape
  - The "Bad" worked example in the skill illustrates the old flat layout (or another anti-pattern) without Wave sub-sections
  - `agents/qrspi-parallelize-reviewer.md` contains a structural rule that requires Branch Map content to be organized under `### Wave N` sub-section headings
  - The new assertion in `tests/unit/test-parallelize-vocab.bats` passes when the reviewer agent file contains the Wave sub-section structural rule and fails (RED) when it is absent
  - Existing symbolic-base-vocabulary and row-completeness assertions in the BATS suite continue to pass
