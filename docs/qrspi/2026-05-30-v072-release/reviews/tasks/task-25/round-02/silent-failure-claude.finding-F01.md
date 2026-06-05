---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - skills/prompt-prose-reviewer/SKILL.md
  - skills/prompt-prose-writer/SKILL.md
reviewer_tag: silent-failure-claude
---

SKILL.md `!cat` chain has no partial-load guard. Round-01 F02 fail-loud guards live INSIDE the addition files; they protect the post-assembly Read of `prompt-design-rules.md`. They do NOT guard the SKILL assembly step itself.

Failure modes:
1. detection `!cat` silently returns empty → addition's "apply the detection above" has nothing to apply; LLM hallucinates / skips / over-applies detection.
2. addition `!cat` silently returns empty → LLM has detection but no action instructions and no fail-loud guards at all.

Fix: add post-`!cat` load-diagnostic note in both SKILL.md files: `"# Guard: if either include above is unavailable, do NOT apply this skill. Surface a load error and stop — partial context is worse than no skill."` If host's `!cat` doesn't support declarative guard, document platform dependency in SKILL.md description.
