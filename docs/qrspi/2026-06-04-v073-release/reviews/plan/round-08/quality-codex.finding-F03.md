---
finding_id: R8-F03
severity: high
change_type: correctness
referenced_files: ["plan.md:L918-L926"]
artifact: plan
round: 8
reviewer: quality-codex
---

T37 adds new script `scripts/measure-active-footprint.sh` (named extension-point add) but lacks `cross_task_consumers:` field.
