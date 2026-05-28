---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L568-L574]
artifact: design
round: 1
reviewer: scope-claude
---

G13's "Concrete shape" subsection embeds a literal shell implementation:

```
skill_slug=$(echo "$path" | sed -n 's|.*/skills/\([^/]*\)/.*|\1|p')
[[ "$skill_slug" == "integrate" ]]
```

and prescribes "Replace the current substring match `[[ "$path" == */integrate/* ]]`."

Per `skills/design/owns-defers.md`, "Line-by-line logic (procedural pseudocode, control-flow detail)" is explicitly DEFERRED to Plan / Implement. Design owns the **approach** ("extract the skill slug from the path under `skills/` and compare only the slug, not the absolute path") and the **rationale** (semantic alignment, robust against any worktree path). The literal sed/regex/test syntax is implementation detail Plan and Implement own.

The Algorithm paragraph immediately above the code block (L566-L567) already states the approach precisely and at the right altitude: "for each candidate file path, find the `skills/` segment. The next path segment is the skill slug. Check that slug against the exclusion list. A file that is not under `skills/` at all yields an empty slug, which matches no exclusion." That's the design-level content.

Recommended fix: remove the "Concrete shape" code block (and its "Replace the current substring match..." line) entirely. The Algorithm paragraph already carries the design-level claim. If Design wants to be more specific, name the contract surface ("the test must extract a skill slug rather than substring-match the absolute path") — not the literal sed invocation. Plan and Implement will land the actual sed/awk/regex.
