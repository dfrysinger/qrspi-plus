---
finding_id: R1-F02
reviewer_tag: quality-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 33 sizing_exception value vs cross-task token convention"
---

## Issue

T33 codifies `sizing_exception: schema-migration` (hyphenated), while other task sizing-exception declarations elsewhere in plan.md use the space-form `schema migration`. The closed sizing-exception enum cannot accept both spellings.

## Why

Whichever validator/reviewer reads sizing_exception will accept one spelling and reject the other. Either T33 fails validation at parse time, or the other tasks do.

## Fix

Pick one canonical token form (recommend hyphenated `schema-migration` since the enum is a code-level identifier, not prose) and normalize all sizing_exception lines across plan.md to match. Cross-link the closed enum surface in structure.md or design.md.
