---
finding_id: F03
reviewer_tag: code-quality-codex
round: 1
severity: medium
change_type: scope
referenced_files:
  - tests/unit/test-change-type-partition.bats:175
  - tests/unit/test-change-type-partition.bats:186
  - tests/unit/test-change-type-partition.bats:213
  - tests/unit/test-change-type-partition.bats:249
  - tests/unit/test-change-type-partition.bats:296
  - tests/unit/test-change-type-partition.bats:315
  - tests/unit/test-change-type-partition.bats:365
  - tests/unit/test-change-type-partition.bats:397
artifact: tests/unit/test-change-type-partition.bats
---

# QRSPI internal IDs are embedded in test names/comments (ID hygiene violation)

Materialized from chat-only response by gpt-5.3-codex.

`G13` and `T04` tokens appear in comments and `@test` names. Per the implementer-protocol ID-hygiene rules, internal tracker-style IDs are forbidden on comment/test surfaces outside `docs/qrspi/`. Use durable referents like behavior names or file paths instead.
