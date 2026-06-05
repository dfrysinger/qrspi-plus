---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/first-party-emission.md:29-33
  - skills/reviewer-protocol/third-party-emission.md:38-42
  - skills/reviewer-protocol/SKILL.md
artifact: task-03
round: 2
reviewer: code-quality-claude
---

# F01 — Schema description duplicated verbatim across both emission siblings (medium · correctness)

Both `first-party-emission.md` (lines 29-33) and `third-party-emission.md` (lines 38-42) reproduce three paragraphs verbatim from `SKILL.md ## Finding Schema`: the "Schema fields" summary, the "Audit fields" description, and the "`finding_id` uniqueness" rule.

The intro of each sibling explicitly states these surfaces "live in `skills/reviewer-protocol/SKILL.md`", making the inline copies a self-contradiction. More importantly, they are a maintenance hazard: any schema change (adding a `change_type` value, renaming an audit field, etc.) must now be applied to three separate locations. Since the sibling files disclaim ownership of the schema, readers updating SKILL.md have no prompt to update the copies, and they will silently drift into incorrectness.

The copies are not abbreviated reminders or targeted summaries — they are character-for-character duplicates of the SKILL.md paragraphs.

**Novel angle not flagged by cq-codex** — Codex flagged the G6 leak; Claude flagged the schema duplication. Both legitimate. T03 R3 in-scope candidate.

**Fix:** Replace the three duplicated paragraphs in each sibling file with a cross-reference: *"Schema fields, audit fields, and `finding_id` uniqueness rules are as defined in `skills/reviewer-protocol/SKILL.md ## Finding Schema`."* If standalone completeness is a hard requirement (e.g., the sibling is assembled into prompts without the core SKILL.md), add an explicit "reproduced here for reference; SKILL.md is authoritative" caveat so future editors know to keep both in sync.
