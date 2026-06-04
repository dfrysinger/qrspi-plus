---
finding_id: R2-F01
reviewer_tag: cq-codex
severity: high
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1957-L1971
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1977-L2043
  - tests/unit/test-verified-file-shape.bats#L144-L149
---

ID hygiene violation: QRSPI-internal token `G28` is present in comments and test-name strings (`[G28 AC*]`, `# G28 ...`, `G28 D1`). Per the strict split rule, G/R/D/T/Q-prefixed numeric IDs are forbidden in comments/test surfaces outside `docs/qrspi/`. Shipping test surface should refer to spec ACs (AC1, AC2, ...) without QRSPI goal-numbering prefix.
