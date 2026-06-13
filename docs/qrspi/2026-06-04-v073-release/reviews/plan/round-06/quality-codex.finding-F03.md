---
finding_id: R6-F03
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L690-L701
artifact: plan
round: 6
reviewer: quality-codex
---

T26 is sweep-shaped and uses the path-list form for `dependent_tests`, but listed paths are not valid existing test-file paths (e.g., `tests/integration/test-cross-skill-contracts.bats`, `tests/acceptance/test-convergence-narrowing.bats`, `tests/unit/test-narrow-round-anchor-lookup.bats`). Under Sweep Task Contract, list-form entries must be concrete existing test files.
