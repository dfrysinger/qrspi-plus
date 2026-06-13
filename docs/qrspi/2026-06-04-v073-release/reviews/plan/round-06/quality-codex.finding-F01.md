---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L835-L849
artifact: plan
round: 6
reviewer: quality-codex
---

T35 is sweep-shaped (>5 same-type files and sweep language) but `dependent_tests: none` is followed by a malformed proof command. Per `skills/plan/SKILL.md` § Sweep Task Contract, the proof must be exactly `grep -rn -- '<pattern>' tests/` (with `--` separator and `tests/` target). The current command targets `skills/.../SKILL.md` and does not match the required shape.
