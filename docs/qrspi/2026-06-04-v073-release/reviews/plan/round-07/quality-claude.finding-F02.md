---
finding_id: R7-F02
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L855-L857"]
artifact: plan
round: 7
reviewer: quality-claude
---

T35 dependent_tests grep proof contains `\|` BRE alternation; Sweep Task Contract forbids `|` character in pattern argument unconditionally (even quoted). Also labeled-bullet vs bare-command shape mismatch. Fix: split into independent bare grep commands per token, or use `-F -e` form.

