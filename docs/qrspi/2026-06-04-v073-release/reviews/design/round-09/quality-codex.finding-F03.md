---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F03
change_type: correctness
---

# G7 rationale contradicts research on per-round commit structure

## Location

design.md L431-436 (G7 rationale); research/summary.md L175-182.

## Finding

G7 claims an "existing two-commit-per-round shape (fix commit + anchor-capture commit)" and chooses anchor-file lookup partly to preserve that shape. Research summary says each apply-fix round produces exactly one git commit; the anchor-capture step writes a SHA file after the commit but does not add another commit.

## Expected fix

Verify against research/summary.md L175-182 and either revise G7 rationale to reflect one-commit-per-round (and re-justify whether `HEAD~1` replacement is still needed) or correct the research-citation.
