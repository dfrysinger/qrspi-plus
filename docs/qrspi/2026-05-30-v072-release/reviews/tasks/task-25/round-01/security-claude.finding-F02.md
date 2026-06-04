---
finding_id: R1-F02
reviewer_tag: security-claude
round: 1
task: 25
severity: medium
change_type: correctness
referenced_files:
  - skills/_shared/prompt-design-rules.md
---

## F02 — `/tmp/` Canonical-Template Reference Becomes Agent-Accessible After Migration

`prompt-design-rules.md` contains:
> "Past reviewer prompts (`/tmp/plan-sizing-review-prompt*.md` from the 2026-04-25 task-sizing amendment) are the canonical templates."

**Before this PR:** file at `docs/prompt-design-guide.md` — outside agent-accessible globs.
**After this PR:** file at `skills/_shared/prompt-design-rules.md` — LLM-consumable.

**Attack scenarios:**
- **A (info disclosure):** agents learn `/tmp/` paths; co-located processes on shared dev machines/CI can read them.
- **B (path-based prompt injection):** attacker drops `/tmp/plan-sizing-review-prompt-injected.md`; overly-literal agent may treat as "canonical."

**Recommendation:** replace `/tmp/` reference with a committed path or remove the sentence — it does not satisfy R1.
