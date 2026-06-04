---
finding_id: R1-F02
reviewer_tag: silent-failure-claude
round: 1
task: 25
severity: high
change_type: correctness
referenced_files:
  - skills/_shared/prompt-prose-writer-addition.md
  - skills/_shared/prompt-prose-reviewer-addition.md
---

## F02 — No fallback when `Read skills/_shared/prompt-design-rules.md` fails

Both addition files issue Read with no error path. Read can fail: plugin not installed, host-convention path resolution differs, file renamed by downstream task, sandbox restriction.

When Read fails, LLM agent silently continues without rules → produces output that looks structurally valid but had no rule enforcement. This is the exact failure mode the addition files exist to prevent.

Fix: add hard-stop guard sentence to both files:
- writer: "If the Read fails, do NOT proceed with authoring. Surface error and stop."
- reviewer: "If the Read fails, do NOT emit findings. Surface error and stop."
