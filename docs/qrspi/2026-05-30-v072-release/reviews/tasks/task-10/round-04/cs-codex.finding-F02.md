---
finding_id: R4-F02
reviewer_tag: cs-codex
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-verified-file-shape.bats:236
---

# cs-codex R4 F02: Helper extraction for sidecar frontmatter tests

Suggestion: extract `extract_sidecar_frontmatter` and `assert_last_field_is_defect_class` helpers to reduce awk/grep/sed duplication.

Disposition: SUGGESTION, file backlog PI-V072-T10-016 (test refactor; v0.7.3).
