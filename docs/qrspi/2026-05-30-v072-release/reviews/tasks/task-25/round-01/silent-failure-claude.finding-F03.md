---
finding_id: R1-F03
reviewer_tag: silent-failure-claude
round: 1
task: 25
severity: medium
change_type: correctness
referenced_files:
  - skills/_shared/prompt-prose-writer-addition.md
---

## F03 — Writer-side addition lacks sub-block detection — mixed-content documents silently misclassified

reviewer-addition.md explicitly mentions "or sub-block, for blocks within larger documents like `design.md`". writer-addition.md only says "apply the detection above to the planned target content" — whole-document framing.

Mixed documents (design.md with both prose and prompt-prose blocks): writer either classifies whole doc as not-prompt-prose (skipping rules) or as prompt-prose (misapplying R1 to ordinary docs). Both silent.

Fix: add sub-block-level guidance to writer-addition matching reviewer's pattern.
