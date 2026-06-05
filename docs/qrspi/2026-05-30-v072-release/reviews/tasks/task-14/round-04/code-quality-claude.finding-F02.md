---
reviewer_tag: code-quality-claude
round: 4
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F02 — `"start"` grep anchor too generic (duplicate of cq-codex R4-F02)

Same as cq-codex R4-F02. The `-`-prefix-rejection pin at L381 uses bare `"start"` which could match unrelated prose. Tighten to `"start with"` or `"NOT start with"` (current rubric prose). 1-line fix.
