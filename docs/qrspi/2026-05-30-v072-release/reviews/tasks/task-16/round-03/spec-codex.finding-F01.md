---
finding_id: R3-F01
reviewer: spec-codex
round: 3
severity: high
change_type: correctness
referenced_files:
  - skills/plan/SKILL.md:134-137
---
plan/SKILL.md still defines and instructs the retired per-task `model` schema as LIVE behavior. The `### Per-Task Classification (task_type and model)` heading (134) and intro paragraph (136) state every task spec "must set task_type and model in its frontmatter" and that "model is forwarded as the per-invocation override on the implementer Agent dispatch." T16 (DoD) requires plan/SKILL.md to no longer document/consume the superseded `model:` field and to emit `tier:` (lightweight→low, ordinary code→medium, escalated code→high). plan/SKILL.md is half-migrated: Step 2 (tier) was added but the section heading + intro still treat `model` as live. Migrate heading/intro to tier-only. CORROBORATED by spec-claude R3-F01. ORCHESTRATOR-VERIFIED via sed.
