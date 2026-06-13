---
finding_id: R6-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L851-L863
artifact: plan
round: 6
reviewer: quality-codex
---

T36 has the same Sweep Task Contract defect as T35: sweep-shaped, `dependent_tests: none`, but search proof is not in the required `grep -rn -- '<pattern>' tests/` form and does not target `tests/`.
