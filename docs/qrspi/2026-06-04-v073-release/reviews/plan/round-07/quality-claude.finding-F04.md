---
finding_id: R7-F04
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L437-L450"]
artifact: plan
round: 7
reviewer: quality-claude
---

T13b adds a new named fix-task mode `revert-orchestration-drift` (anchor-heading add) but lacks `cross_task_consumers:` field. T36 is consumer (must preserve mode prose verbatim through trim). Add `cross_task_consumers: T36 (pass-through)`.

