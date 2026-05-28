---
finding_id: R3-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1294-L1296]
artifact: plan
round: 3
reviewer: goal-traceability-claude
---

T43's "Target files" section lists `docs/qrspi/2026-05-17-v07-release/plan.md (Modify)` as a target file. The immediately following parenthetical explanation on the same line says "Slice 7 acceptance block already carries a conditional Path B criterion bullet (added by goal-traceability fix); no further edits to plan.md acceptance are required for this task."

A target file that the task spec explicitly says will not be edited should not appear as a target file. Listing it creates a contradiction: the implementer sees `plan.md` in the target file list and could infer an edit is expected, but the explanatory note says no edit is needed. This misleads both the implementer and the per-task reviewer about what the task will change. It also conflates the plan-authoring step (where the goal-traceability reviewer's round-2 finding caused the bullet to be added) with the implementation step (T43) — the acceptance bullet is already in place; T43 has no plan.md responsibility.

Fix: remove the `docs/qrspi/2026-05-17-v07-release/plan.md (Modify)` bullet from T43's "Target files" section entirely. The entry carries no implementation work and its presence is misleading. The Slice 7 acceptance block already reflects the correct state from round-2 edits, and T43's task description and test expectations accurately describe its conditional scope (Path B marker insertion in `scripts/run-third-party-llm.sh` only, or NO-OP under Path A).
