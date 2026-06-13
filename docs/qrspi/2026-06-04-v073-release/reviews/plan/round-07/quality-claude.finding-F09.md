---
finding_id: R7-F09
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L862-L876"]
artifact: plan
round: 7
reviewer: quality-claude
---

T36 trim of integrate/SKILL.md and test/SKILL.md is a named extension-point remove but lacks `cross_task_consumers:`. T24 (independent lint) depends on T21/T22 NOT T36; would silently break if T36 removes phase-base.txt write-step anchors. Add `cross_task_consumers: T24 (pass-through)`, prose disposition that T36 must preserve those anchors verbatim.

