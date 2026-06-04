---
finding_id: R1-F01
reviewer_tag: silent-failure-claude
round: 1
task: 25
severity: high
change_type: correctness
referenced_files:
  - skills/_shared/prompt-design-rules.md
---

## F01 — Dead `/tmp` path offered as "canonical template" — LLM agent silently finds nothing

> "Past reviewer prompts (`/tmp/plan-sizing-review-prompt*.md` from the 2026-04-25 task-sizing amendment) are the canonical templates."

`/tmp/` is ephemeral; files don't exist at plugin install time or persist across sessions. LLM agent instructed to "use the canonical templates" attempts a lookup that returns nothing → proceeds with ad-hoc prompt OR silently omits reviewer-prompt section. Violates R1 directly.

Fix: remove the `/tmp/` sentence entirely, or replace with pointer to in-repo six-part structure.

(Note: overlaps with security-claude F02 — different angle: sf treats this as silent-fail surface; sec treats as path-injection surface. Same underlying cause: stale `/tmp/` reference now LLM-consumable.)
