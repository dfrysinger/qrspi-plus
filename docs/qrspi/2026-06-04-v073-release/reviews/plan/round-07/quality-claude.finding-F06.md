---
finding_id: R7-F06
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L645-L657"]
artifact: plan
round: 7
reviewer: quality-claude
---

T21 adds HARD-RULE OBC section + `### Step N` heading to integrate/SKILL.md (anchor-heading adds) but lacks `cross_task_consumers:`. T24 (independent lint, grep-asserts phase-base.txt write-step anchor) and T36 (trim must preserve) are consumers. Add `cross_task_consumers: T24 (pass-through), T36 (pass-through)`.

