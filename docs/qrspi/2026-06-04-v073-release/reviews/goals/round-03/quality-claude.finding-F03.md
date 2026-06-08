---
finding_id: R3-F03
severity: low
change_type: style
referenced_files: ["docs/qrspi/2026-06-04-v073-release/goals.md:L186-L187"]
artifact: goals
round: 3
reviewer: quality-claude
---

G9's header-area formatting diverges from the schema pattern used by all other goals in two ways:

1. **`type` field format (L186).** All other goals write the type as `- **type:** \`known-fix\`` — a bullet, lowercase key, backtick-quoted value. G9 writes `**Type:** known-fix` — capitalized key, no bullet, no backticks. The value `known-fix` is correct, but the inconsistent format may confuse automated parsers that key on the exact pattern.

2. **Extra `**Research status:** deferred (...)` field (L187).** This line has no counterpart in any other goal. It is not one of the three required subsections, and the goals schema defines no `Research status` field. Content about research scope would normally live as a note inside `#### What we know so far`.

Fix: rewrite the two header lines to match the canonical pattern:
```
- **type:** `known-fix`
```
and remove the `**Research status:**` line (or absorb its content into `#### What we know so far` if it provides useful context for Design).
