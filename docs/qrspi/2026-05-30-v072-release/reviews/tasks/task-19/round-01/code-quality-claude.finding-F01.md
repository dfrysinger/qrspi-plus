---
finding_id: F01
reviewer_tag: code-quality-claude
severity: low
change_type: style
referenced_files:
  - skills/goals/SKILL.md:260
---

## Stale section heading: "**Codex reviews**" after vendor-neutral field rename

The diff changed the gating condition from `codex_reviews: true` to `second_reviewer: true`
(correct) but left the bold section heading text "**Codex reviews**" unchanged:

```diff
-- **Codex reviews** (if `codex_reviews: true`) — dispatch TWO non-blocking Codex reviews
+- **Codex reviews** (if `second_reviewer: true`) — dispatch TWO non-blocking Codex reviews
```

The heading now reads "**Codex reviews** (if `second_reviewer: true`)" — the heading is
vendor-specific while the field is vendor-neutral. Every other changed site in the diff
(goals, using-qrspi, reviewer-protocol) uses "Second-model reviews" / "second-reviewer"
language. This is the one site where only the condition was updated without the heading text.

**Suggested fix:** Rename the heading to "**Second-model reviews**" to match the migration
vocabulary used throughout the rest of the diff.
