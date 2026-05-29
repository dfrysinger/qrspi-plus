<<<FINDING-BOUNDARY>>>
---
finding_id: F01
reviewer_tag: quality-codex
round: 1
artifact: task-10
severity: medium
change_type: clarity
referenced_files:
  - skills/using-qrspi/SKILL.md:448-460
  - skills/using-qrspi/SKILL.md:494
  - skills/using-qrspi/SKILL.md:511-535
  - docs/qrspi/2026-05-27-v071-hardening/config.md:81-106
---

`skills/using-qrspi/SKILL.md` now contains two incompatible schemas for `model_routing`, which creates an ambiguity that can drive incorrect future edits/implementations. The pre-existing `#### \`model_routing:\` block` section still defines `model_routing` as `role -> provider/model` (lines 448-460) and the precedence chain still says "role lookup" (line 494). The new `#### Model Routing` section (lines 511-535) defines `model_routing` as `host -> tier -> model-id`, matching Task 10 and `config.md`. These cannot both be true. Evidence: side-by-side text in the same file conflicts, and TE6 only checks that the new section exists, not that the old contradictory schema was removed/updated. This is a real quality defect because SKILL.md is operational guidance for pipeline agents; contradictory schema docs can cause wrong config generation/validation behavior.

**Independently corroborates `quality-claude.finding-F01.md`. Verifier-scored that finding at 80 (AT clarity KEEP threshold). Same defect; no need to verifier-score a second time.**
