---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/questions.md:L15
artifact: questions
round: 1
reviewer: quality-claude
---

Q9 leaks solution direction. The second clause ("which reference it only by pointer?") introduces a binary categorisation that maps directly onto a known candidate fix — inlining the HARD-RULE in pointer-only files. A researcher reading Q9 alone can deduce the intent.

Rewrite to ask for a plain inventory: "How is the Orchestration Boundary HARD-RULE currently distributed across skill files — what are the scope and verbosity of its appearance in each SKILL.md that references it?"
