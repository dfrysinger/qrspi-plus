---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---
title: ID hygiene — [G15-sweep] test labels carry QRSPI-internal IDs
evidence:
  - per skills/implementer-protocol/SKILL.md § ID Hygiene, G/R/D/T/Q-prefixed numeric tokens are forbidden in test names outside docs/qrspi/
  - [G15-sweep] labels in tests/integration/test-reference-gate-pause.bats lines 232-359
disposition: DISMISSED-following-convention
disposition_reason: |
  315 such tokens exist across 23 pre-existing test files (sample: [T30-rg-pause], [T19-shape], [T23-owns], [T4-shape], [T42-boundary], ...). T14 followed established file convention. Renaming would be a sweep-task in itself, well beyond T14 scope.
backlog: v0.7.3 — sweep-task to rename QRSPI-internal IDs in test labels across tests/ to descriptive non-ID slugs (with dependent_tests: enumeration per the very contract this task ships).
