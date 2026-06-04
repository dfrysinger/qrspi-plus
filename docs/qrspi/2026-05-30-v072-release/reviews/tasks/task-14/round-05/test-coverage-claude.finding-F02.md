---
finding_id: R5-F02
reviewer_tag: test-coverage-claude
round: 5
severity: low
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---

# F02: Malformed dependent_tests variants pin uses broad alternation regex

Same finding as tc-codex F02 (independent convergence). Lines 314-320 use broad alternation regex (`malformed|no paths|no .none.`) instead of variant-specific section-scoped assertions per the 4 named malformed variants (missing-field, no paths, `none` without grep, `none` with non-zero grep hits).

## Fix pattern

Replace each broad alternation with explicit `extract_and_grep ... H3 "Sweep-task detection" <variant-specific-pattern>` — one per named variant. (Note: lines 317 + 319 are already reasonably specific; line 318 is the main offender.)
