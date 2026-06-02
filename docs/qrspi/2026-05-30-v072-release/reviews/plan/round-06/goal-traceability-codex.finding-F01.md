---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Forward goal→task traceability is not 100% complete: goals G25 and G29 have no Task-spec Goal ID mapping in this artifact.

Evidence:
- The plan claims "**35 approved goals decomposed ... into 38 tasks**" (plan.md:11), which implies full forward goal coverage.
- The same line also states "**G25 ... absorbed by CD-1**" and "**G29 ... ships no standalone task**" (plan.md:11).
- Across all 38 Task Specs (`### Task XX` blocks), Goal ID lines map tasks to goals, but no Task-spec `Goal IDs` entry includes G25 or G29; e.g. T11 is explicitly relabeled to G3 (`Goal IDs: [G3]`, plan.md:679) and T40 maps `[G21, G26]` (plan.md:2289), leaving G25/G29 without any task row.

This breaks the stated "35-goal forward" completeness condition unless the matrix explicitly represents absorbed goals with a non-task disposition row.
