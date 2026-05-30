---
finding_id: R6-F01
severity: medium
change_type: traceability
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/structure.md]
artifact: plan
round: 6
reviewer: quality-claude
---

structure.md Slice 7 SKILL.md row omits cache_control; plan/structure drift

R5 added cache_control to plan.md Task 8 description and test expectation, matching the automated assertion. structure.md Slice 7 SKILL.md row (line 66) still reads "Remove supports_prompt_cache and emit_cache_control_markers from the providers block" — omits cache_control.

Implementer reading only structure.md wouldn't know to remove cache_control from SKILL.md.

Fix: Update structure.md Slice 7 SKILL.md row to: "Remove cache_control, supports_prompt_cache, and emit_cache_control_markers from the providers block (both the YAML example values and the description bullets)"

DISPOSITION: ACCEPT — one-line structure.md fix. Mirror of the plan.md FIX 5 from R5, just propagating to the structure.md row that was missed.
