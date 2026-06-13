---
finding_id: R9-F01
severity: high
change_type: correctness
referenced_files: ["plan.md:L932"]
artifact: plan
round: 9
reviewer: quality-codex
---
T37 cross_task_consumers: none grep proof lacks `--` argument separator (`grep -rn 'pattern' . --exclude-dir=...` should be `grep -rn -- 'pattern' . --exclude-dir=...`). Pedantic per SKILL contract (command shape is left to author, pattern doesn't start with `-` so no actual ambiguity) but harmless to fix for hygiene.
