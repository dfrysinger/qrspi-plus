---
finding_id: F01
reviewer_tag: code-quality-codex
round: 1
severity: medium
change_type: clarity
referenced_files:
  - tests/unit/test-change-type-partition.bats:355-360
  - tests/unit/test-change-type-partition.bats:403-409
artifact: tests/unit/test-change-type-partition.bats
---

# Underpowered regex checks contradict their own "any permutation" claims

Materialized from chat-only response by gpt-5.3-codex.

Both tests describe matching enum alternations "in any order," but the implemented patterns only match one (or two) specific orderings. This makes the tests weaker than documented and can miss duplicated enum lists arranged differently from the canonical order.
