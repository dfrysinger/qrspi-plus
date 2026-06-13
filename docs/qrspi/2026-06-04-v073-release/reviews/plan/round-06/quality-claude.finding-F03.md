---
finding_id: R6-F03
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1331-L1334
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1347-L1350
artifact: plan
round: 6
reviewer: quality-claude
---

T35 and T36 are sweep-shaped with `dependent_tests: none`, but their grep proofs are malformed: use `-rEn` instead of `-rn`, omit `--` separator, target `skills/{...}/SKILL.md` instead of `tests/`. The semantic intent is inverted — they audit subject files rather than consumer tests.

Fix for both: replace with `grep -rn -- '<pattern>' tests/` form. The `--` separator and `tests/` path are required by the Sweep Task Contract.

