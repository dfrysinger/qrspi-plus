---
finding_id: R9-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
artifact: structure
round: 9
reviewer: scope-codex
---

## File-map entry embeds deferred content-level text

**File:** structure.md L129
**Severity:** Medium
**Problem:** The updated File Map row at L129 includes a literal anchor phrase (`"Scope: only \`task_type: code\` tasks."`) and exact placement instruction ("at the TOP ..."). That crosses Structure's scope boundary from location/interface mapping into content/assertion text.

**Evidence:**
- Delta adds literal phrase text in the Structure File Map responsibility field (line 129).
- Structure DEFERS explicitly excludes "Actual prompt or SKILL.md text content" and "Test assertion code / full assertion text" (skills/structure/owns-defers.md:17,20-21).

**Suggested fix:** Keep this row at location/contract altitude only (e.g., "pin Addition C presence at review-procedure top location"), and remove the literal phrase/assertion text from structure.md.

**Note:** Independently corroborated by scope-claude R9-F01 from a different angle (same finding from two reviewers).
