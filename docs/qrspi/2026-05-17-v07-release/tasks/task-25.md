---
task: 25
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G11]
dependencies: [T24]
loc_estimate: 90
---

# Task 25: Add Structure-skill UI Reference Affordances section spec for sibling reference repo, lift codemod, and image-asset pipeline

- **Phase:** 1
- **Target files:**
  - `skills/structure/SKILL.md` (Modify) — add optional `## UI Reference Affordances` section spec; captured once per release for sibling reference repo, lift codemod, and image-asset pipeline; required when any task spec carries `lift_source:`.
- **Dependencies:** T24
- **LOC estimate:** ~90
- **Description:** Extends `skills/structure/SKILL.md` with an optional `## UI Reference Affordances` section spec that consumes the `lift_source:` frontmatter field T24 introduces. The section spec documents three affordances Structure records once per release rather than re-deriving per task: the sibling reference repo path (where the coded prototype lives — sibling repo, scratch directory, or upstream pinned commit), the lift-codemod transformation (token import codemod or equivalent mechanical lift recipe that translates source tokens into the target's design-system vocabulary), and the image-asset pipeline (where reference PNG/SVG/PDF artifacts live and how they reach the target tree). The section spec is optional at the Structure-skill level but BECOMES REQUIRED at the structure.md instance level when any task spec in the same release carries `lift_source:` — Structure refuses to mark `structure.md` approved if a `lift_source:` task exists in the plan without a corresponding `## UI Reference Affordances` section. The new section spec also documents the consumer contract: T28's refined visual-fidelity reviewer Reads `## UI Reference Affordances` from `structure.md` to ground its lift-verbatim-vs-re-derive judgments. Adds a Red Flags entry that fires when a plan contains `lift_source:` tasks but `structure.md` lacks `## UI Reference Affordances`. The Structure-skill body change is markdown prose and template-spec only — no code surface — so the lightweight/sonnet classification holds. Operator may flip to opus before approval if the section-spec shape warrants the upgrade.
- **Test expectations:**
  - `skills/structure/SKILL.md` documents the `## UI Reference Affordances` section spec with the three affordances (sibling reference repo path, lift-codemod transformation, image-asset pipeline) enumerated.
  - The section spec states the consumer contract that T28's visual-fidelity reviewer Reads `## UI Reference Affordances` from `structure.md` for lift-verbatim-vs-re-derive grounding.
  - The section spec states the conditional-required rule: when any task spec in the release carries `lift_source:`, `structure.md` MUST contain `## UI Reference Affordances`.
  - A Red Flags entry fires when a plan contains `lift_source:` tasks but `structure.md` lacks the section.
  - Behavioral refusal: when a fixture `plan.md` contains a task with `lift_source:` but the corresponding `structure.md` is missing the `## UI Reference Affordances` section, the Structure skill returns a named refusal at its approval step rather than marking `status: approved` — observable in the skill's exit behavior, not only in the Red Flags table's prose.
