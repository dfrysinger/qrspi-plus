---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Phase 1 Acceptance Criteria → "Full bats suite is green against deduplicated helpers..."
referenced_files: [plan.md, goals.md, design.md]
---

# F01 — Phase-level acceptance still requires a moot G24-F03 deliverable with no backing task

`plan.md:25` requires "the consolidated H4-extraction helper passes its tests."  
But the task set no longer contains any G24-F03 helper-consolidation task (`plan.md:93-95` shows only T40 [G21,G26] and T44 [G24] in this slice), and T44 explicitly marks helper promotion as out-of-scope/moot (`plan.md:2370-2371`).  
Design also locks F03 as moot because cross-file duplication does not exist (`design.md:2063`), so this acceptance criterion is no longer traceable to planned implementation work.
