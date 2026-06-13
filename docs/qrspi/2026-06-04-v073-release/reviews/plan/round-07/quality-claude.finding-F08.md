---
finding_id: R7-F08
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L673-L683"]
artifact: plan
round: 7
reviewer: quality-claude
---

T23 adds `### Orchestration Boundary applies to every phase` heading to using-qrspi/SKILL.md (anchor-heading add) but lacks `cross_task_consumers:`. T32 is consumer (trim must preserve). Add `cross_task_consumers: T32 (pass-through)`.

