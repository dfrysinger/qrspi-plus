---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files:
  - plan.md:L29
---

# Per-task test-spec location is declared incorrectly; `tasks/` directory does not exist

**Problem.** Plan.md L29 reads: "(Per-task criteria live in each `tasks/task-NN.md`'s `## Test Expectations` block; the per-phase block above captures cross-task observable behavior at phase end.)" — but `tasks/task-NN.md` files do not exist under `docs/qrspi/2026-05-30-v072-release/tasks/` (the directory itself is absent). All per-task Test Expectations are currently inline inside plan.md under the `## Task Specs` section (each task's `**Test expectations**` block).

**Evidence.**
- `plan.md` L29 declares `tasks/task-NN.md` as the source of per-task criteria.
- `ls docs/qrspi/2026-05-30-v072-release/tasks/` → "No such file or directory".
- Task sections with `**Test expectations**` are present directly in `plan.md` (e.g., Task 01 at L156-L163, Task 02 at L210-L217).
- Sibling directory `tasks-enhanced/` exists (intermediate work) but is not the path L29 names.

**Impact.** Any reviewer/implementer/automation that follows the L29 contract will fail to load per-task specs from the declared path. The Implement skill in particular reads `tasks/task-NN.md` for per-task dispatch — a stale path declaration here will misroute consumers.

**Suggested fix.** Two paths; pick one:
- (a) Update L29 to reflect the current reality: "(Per-task criteria live inline in this file under each task's `**Test expectations**` block in the `## Task Specs` section; per-task `tasks/task-NN.md` files will be generated from the inline specs during the plan-split step before Implement.)"
- (b) Materialize `tasks/task-NN.md` files now (one per task), each containing the inline Test Expectations block extracted from plan.md, and keep the L29 statement as-is.

User context (recorded in checkpoint history): plan.md is currently in aggregated form for human review; the split into per-task files is a planned downstream step. Path (a) is the lower-friction fix that documents the current state; path (b) is the higher-friction fix that delivers the split now.
