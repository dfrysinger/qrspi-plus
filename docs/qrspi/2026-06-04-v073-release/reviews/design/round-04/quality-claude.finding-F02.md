---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md:L279-L309"]
artifact: design
round: 4
reviewer: quality-claude
---

The two G5 prose-design blocks for `skills/integrate/SKILL.md § Orchestration Boundary` (~design.md L279–L294) and `skills/test/SKILL.md § Orchestration Boundary` (~L295–L309) contain malformed Markdown fence nesting that makes the verbatim content boundary ambiguous.

Each block opens an outer triple-backtick fence, then immediately opens another triple-backtick fence to display the HARD-RULE literal block. In standard Markdown parsing, the second ` ``` ` closes the outer fence — the `### Orchestration Boundary` heading is the only content inside the outer code fence, the HARD-RULE text appears as unformatted paragraph text, and the subsequent narrative prose appears inside a second code fence.

Fix: restructure both blocks to use a single outer fence (e.g., tilde fences `~~~` outer, or 4-space indent for HARD-RULE inner).

