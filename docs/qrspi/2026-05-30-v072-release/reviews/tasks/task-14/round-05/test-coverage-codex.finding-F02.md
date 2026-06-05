---
finding_id: R5-F02
reviewer_tag: test-coverage-codex
round: 5
severity: low
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---

# F02: Malformed `dependent_tests:` variant coverage uses broad alternation regex

Lines 314-320: pin uses broad regex alternations (`malformed|no paths|no .none.`) instead of variant-specific section-scoped assertions per the three named malformed variants (missing-field, no paths, `none` without grep, `none` with non-zero grep hits).

Risk: pin can pass even if one or more required malformed variants are not explicitly documented in the sweep rubric section.

## Adjudication: ACTIONABLE — surgical pin tightening

This is the same class of issue as the R5 `"start"` → `"NOT start with"` tightening. Address surgically by:
1. Replacing the broad alternation on lines 314-320 with three explicit section-scoped `extract_and_grep` assertions, one per named variant.
2. Anchored to the Sweep-task detection section, not file-level.

This is exactly the surgical tightening pattern user has authorized; ~10-15 LOC test-only change.
