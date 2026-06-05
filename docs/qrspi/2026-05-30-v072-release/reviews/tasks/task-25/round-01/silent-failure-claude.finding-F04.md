---
finding_id: R1-F04
reviewer_tag: silent-failure-claude
round: 1
task: 25
severity: medium
change_type: correctness
referenced_files:
  - skills/_shared/prompt-prose-reviewer-addition.md
---

## F04 — "Standard reviewer schema" instructed but never defined or referenced

reviewer-addition.md says: "Emit findings using the **standard reviewer schema**, tagged: change_type..." Schema is named but not defined; wrapper SKILL chains only two `!cat` directives, no schema definition.

If skill loaded standalone, agent has no schema → emits findings in self-invented plausible-looking format → orchestrator receives syntactically-valid markdown that doesn't parse against expected schema. Silent schema deviation.

Fix: add pointer to authoritative schema location (e.g., `using-qrspi/SKILL.md` § Reviewer Output Format or `reviewer-protocol/SKILL.md`). Tell agent to stop-and-read if schema not in context.
