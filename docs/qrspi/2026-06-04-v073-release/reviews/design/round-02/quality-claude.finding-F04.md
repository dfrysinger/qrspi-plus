---
finding_id: R2-F04
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/design.md:L687-L701
  - docs/qrspi/2026-06-04-v073-release/design.md:L703-L717
artifact: design
round: 2
reviewer: quality-claude
---

The prose-design fenced blocks for G5's Orchestration Boundary sections (integrate/SKILL.md at L687–L701 and test/SKILL.md at L703–L717) use ` ``` ` (3 backticks) as the outer fence, which collides with the inner ` ``` ` fence used for the HARD-RULE block. In standard Markdown, the outer fence closes at the first matching inner fence — the closing ` ``` ` at L691/L707 (the inner HARD-RULE opening) terminates the outer prose-design block prematurely, leaving only `"### Orchestration Boundary"` as the scoped content. Everything from the HARD-RULE block through the "Why this rule matters" paragraph is rendered outside the prose-design block boundary.

An implementer reading these blocks cannot tell from the rendered design whether the HARD-RULE block and "Main chat's responsibilities…" / "Main chat does NOT:…" / "Why this rule matters…" paragraphs are part of the content to be inserted, or simply adjacent commentary. By contrast, CD-3's prose-design block at L471 correctly uses ```` ```` ```` (4 backticks) as the outer fence when the inner content contains ` ``` ` code blocks.

Fix: Change the outer ` ``` ` fences for both the integrate/SKILL.md (L688/L701) and test/SKILL.md (L704/L717) prose-design blocks to ```` ```` ```` (4 backticks), matching the pattern established by CD-3.
