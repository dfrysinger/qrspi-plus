---
finding_id: R5-F01
severity: medium
change_type: traceability
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/structure.md]
artifact: plan
round: 5
reviewer: quality-codex
---

Task 8 adds test-cache-retirement-invariants.bats but structure.md Slice 7 doesn't include it

R4 fix synthesis added new file to avoid Task 8 self-referential grep trap (spec-claude R4-F02). But this drifts plan from structure.md, which doesn't list this file in Slice 7 file map.

Fix options:
(a) Add file to structure.md Slice 7 (update Structure artifact — out-of-scope for plan-step now)
(b) Inline the assertions in an already-declared file using anchored patterns

DISPOSITION: ACCEPT — option (a). Structure.md needs a small update to add this file to Slice 7. The structure-fidelity check is correct: introducing a new file in plan that isn't in structure.md is a traceability drift. The cleanest fix is to add the file to structure.md (structure-edit needs scope re-review but is minimal). Alternative: revert FIX 2 to use anchored patterns in test-phase1-acceptance.bats.

WILL APPLY: Option (a) — add file to structure.md.
