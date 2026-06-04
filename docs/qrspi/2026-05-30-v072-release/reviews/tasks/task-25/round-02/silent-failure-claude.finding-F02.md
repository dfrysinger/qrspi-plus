---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - skills/_shared/prompt-prose-reviewer-addition.md
reviewer_tag: silent-failure-claude
---

Reviewer-addition fail-loud guard uses ambiguous `"stop"` inside a per-file loop. Guard is placed inside "For each file" loop; `"stop"` syntactically ambiguous: per-iteration stop allows silent partial enforcement when first-file Read fails transiently and later Reads succeed (files 2-5 reviewed under rules, file 1 silently dropped, orchestrator receives valid findings with no indication of partial enforcement).

Contrast: writer-addition is not in a loop — `"stop"` there is unambiguous.

Fix: `"...stop the review entirely — do not proceed with any further files."`
