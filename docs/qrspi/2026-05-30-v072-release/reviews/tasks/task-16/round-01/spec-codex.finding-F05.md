---
finding_id: R1-F05
reviewer: spec-codex
round: 1
severity: medium
change_type: missing-test
referenced_files:
  - tests/unit/test-config-model-routing.bats:66-87
  - tests/unit/test-config-model-routing.bats:151-154
  - tests/unit/test-routing-matrix-application.bats
---
Test-coverage gap that allowed the partial migration (F01/F02/F03) to pass 74/74. The suite still pins deprecated model-era behavior (per-task `model:` precedence, `model_role:` references) and does NOT assert removal of the retired host-keyed schema from using-qrspi/SKILL.md (#### Model Routing, precedence-chain old step 3, missing-block warning/backfill) nor from test/SKILL.md (hardcoded model:"sonnet"). The DISPATCH_FILE pins check only 5 reviewers, missing qrspi-code-simplifier + qrspi-type-design-analyzer (see spec-claude R1-F01). Tighten assertions to guard the FULL migrated surface so retired-schema residue fails CI.
