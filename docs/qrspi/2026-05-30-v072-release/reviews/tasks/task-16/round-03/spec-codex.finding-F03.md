---
finding_id: R3-F03
reviewer: spec-codex
round: 3
severity: medium
change_type: test_coverage
referenced_files:
  - tests/unit/test-routing-matrix-application.bats:242-279
---
The updated routing-matrix bats tests guard implement/using-qrspi residue (absence of hardcoded model:"sonnet", presence of tier mentions) but do NOT guard the plan/SKILL.md per-task `model` schema residue, the implement § Model Selection Guidance haiku/sonnet/opus table, or the role-keyed G5 matrix removal — gaps that let R3-F01/F02 and claude-R3-F03 persist undetected through two prior rounds. T16 test expectations require grep coverage confirming the old per-host schema, role-keyed G5 routing matrix, and `model:` task-routing field guidance are gone from ALL FOUR migrated surfaces (using-qrspi, implement, plan, test). Add pins covering plan/SKILL.md and the Model Selection Guidance table. ORCHESTRATOR-VERIFIED.
