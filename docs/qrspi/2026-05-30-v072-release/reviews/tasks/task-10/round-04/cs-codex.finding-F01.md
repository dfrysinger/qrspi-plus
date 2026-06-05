---
finding_id: R4-F01
reviewer_tag: cs-codex
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2082
---

# cs-codex R4 F01: Helper extraction for repeated YAML grep blocks

Suggestion: extract `assert_yaml_has` / `assert_yaml_lacks` helpers and iterate required/forbidden patterns to reduce duplication in AC5.

Disposition: SUGGESTION, file backlog PI-V072-T10-015 (test refactor; v0.7.3).
