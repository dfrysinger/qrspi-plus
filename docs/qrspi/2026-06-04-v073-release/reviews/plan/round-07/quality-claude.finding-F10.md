---
finding_id: R7-F10
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L846-L860"]
artifact: plan
round: 7
reviewer: quality-claude
---

T35 trim of 8 artifact-step SKILLs is a named extension-point remove but lacks `cross_task_consumers:`. T06 lint depends on T05 NOT T35; could silently break if T35 removes T05's dispatch-agent invocations. Add `cross_task_consumers: T06 (pass-through)`.
