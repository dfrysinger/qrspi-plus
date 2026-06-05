---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 11, 18, 41 — G25/G26/G29 absorbed-goal status"
referenced_files:
  - plan.md
  - design.md
---

# F01 — Plan creates standalone tasks for goals design marked moot/absorbed

## Defect

Design.md explicitly says no separate v0.7.2 task ships under these goal IDs:
- G25: design.md ~2110 ("no separate v0.7.2 task ships under the G25 ID")
- G26: design.md ~2151 (same wording)
- G29: design.md ~2336 (same wording)

Plan still creates standalone tasks:
- Task 18 → G25
- Task 41 → G26
- Task 11 → G29

## Impact

Plan violates design's CD-level decisions. If the goals were absorbed into other goals' work, the standalone tasks duplicate that work, create coordination overhead, and re-introduce content design explicitly retired.

## Recommended fix

Either (a) verify that T11/T18/T41 actually carry distinct work that wasn't absorbed by their merging goals (and update their goal-ID references in the spec to reflect the absorbing goal), OR (b) remove the standalone tasks and merge any residual work into the absorbing tasks. The design.md absorption language is the source of truth.

## Verification note

Need to cross-check whether T11/T18/T41 specs actually duplicate other tasks' work, OR whether they carry residual scope the absorption didn't cover. If the latter, they should be re-labeled with the absorbing goal's ID + "residual" qualifier; if the former, removed.
