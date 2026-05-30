---
artifact: design
reviewer: scope-claude
round: 1
finding_id: scope-claude-F01
severity: medium
change_type: scope
file: design.md
section: "DKR8"
lines: 67-68
---

# F01: DKR8 Reasoning pre-enumerates the exact file line ranges it explicitly defers to Plan

## Evidence

DKR8 Reasoning enumerates exact line ranges (`skills/using-qrspi/SKILL.md lines 427-428 + 441-442`, etc.) while DKR8's Decision block says "Plan enumerates the exact line ranges." The deferral is undermined by the reasoning supplying those ranges.

## Rule violated

Specific source-file line ranges are Plan / Implement territory per the DEFERS contract ("Line-by-line logic → Plan / Implement").

## Required fix

Remove the line-number citations from the Reasoning and replace them with file-level scoping only (e.g., "the SKILL.md cache-hint block and the shell cache gate").
