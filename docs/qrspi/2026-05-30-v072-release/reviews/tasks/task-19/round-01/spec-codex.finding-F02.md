---
finding_id: F02
reviewer_tag: spec-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:L28-L29
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:L44
  - skills/using-qrspi/SKILL.md:L406-L419
---
`skills/using-qrspi/SKILL.md` still contains live behavior prose keyed on legacy `codex_reviews`
(mismatch policy and unavailability short-circuit). This conflicts with Task 19's required
migration to canonical `second_reviewer` semantics and the "reject legacy `codex_reviews:`"
config-validation stance.
