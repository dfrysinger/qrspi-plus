---
finding_id: R4-F02
severity: low
change_type: style
referenced_files: [tests/unit/test-verified-file-shape.bats]
---

# Duplicated frontmatter-extraction pattern

The "success template" and "failure template" field-order tests share a verbatim 7-line sequence: extract `$fm` from a `$block` via `awk`, check it's non-empty, extract the last YAML key via `grep`+`sed`, and assert it equals `"defect_class"`. Only the `awk` producing `$block` differs. A `_assert_defect_class_last` helper would eliminate the duplication while keeping each test's unique logic (the success test's extra `score_line`/`defect_line` ordering check) separate.
