---
task: 6
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G1, G5]
dependencies: [T01]
loc_estimate: 15
---

# Task 06: Declare model_role frontmatter on specialist, collator, and lightweight-implementer agents

- **Phase:** 1
- **Target files:**
  - `agents/qrspi-research-specialist.md` (Modify) — add `model_role: research-specialist` frontmatter alongside the existing `model:` value.
  - `agents/qrspi-research-collator.md` (Modify) — add `model_role: research-collator` frontmatter alongside the existing `model:` value.
  - `agents/qrspi-implementer-lightweight.md` (Modify) — add `model_role: lightweight-implementer` frontmatter alongside the existing `model:` value.
- **Dependencies:** T01
- **LOC estimate:** ~15
- **Description:** Adds a single `model_role:` frontmatter field to each of the three Slice 1 agent files so the layer-2 resolution step from T05's routing chain has an authoritative role label to look up against the `model_routing:` block authored under T01's schema. The existing `model:` frontmatter value is preserved as the layer-3 bundled default; the new `model_role:` field is purely additive and carries no runtime behavior of its own — it only exists for the dispatcher's role-to-provider+model resolution. The three role labels (`research-specialist`, `research-collator`, `lightweight-implementer`) match the candidate dispatcher-tolerance leaves identified in goals.md G5 so the matrix authored by Implement can be tuned against the same role vocabulary. No body prose changes; no other agent files touched in this task.
- **Test expectations:**
  - `agents/qrspi-research-specialist.md` carries `model_role: research-specialist` in its YAML frontmatter alongside the existing `model:` value, with both fields valid YAML.
  - `agents/qrspi-research-collator.md` carries `model_role: research-collator` in its YAML frontmatter alongside the existing `model:` value.
  - `agents/qrspi-implementer-lightweight.md` carries `model_role: lightweight-implementer` in its YAML frontmatter alongside the existing `model:` value.
  - The existing `model:` value on each of the three agents is unchanged (preserved as the layer-3 default).
  - The three role-label strings exactly match the role names consumed by the T01 `model_routing:` schema (no typo, no whitespace drift).
  - No agent body prose outside the frontmatter is modified in this task.
