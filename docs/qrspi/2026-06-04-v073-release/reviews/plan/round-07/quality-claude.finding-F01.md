---
finding_id: R7-F01
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L395-L399"]
artifact: plan
round: 7
reviewer: quality-claude
---

T11 dependent_tests uses 3 labeled-bullet "Search proof" lines after `none`; Sweep Task Contract requires single bare `grep -rn -- '...' tests/` command on the next line. Fix: emit three independent bare grep commands (one per token class) or one combined pattern free of `|`.

