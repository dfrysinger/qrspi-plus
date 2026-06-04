---
finding_id: R4-F02
reviewer_tag: gt-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:50
  - agents/qrspi-finding-verifier.md:94
  - tests/unit/test-verified-file-shape.bats:168
---

# gt-codex R4 F02: Missing test coverage for documented examples

Spec L50 requires test asserting examples are documented. Implementation has examples at agent L94, but no test pins their presence. Regression removing them would not fail.

CONVERGENT with tc-codex R4 F04. Disposition: covered by PI-V072-T10-013 (same as tc-codex F04).
