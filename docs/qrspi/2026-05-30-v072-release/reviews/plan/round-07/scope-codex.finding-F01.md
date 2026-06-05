---
reviewer: codex
role: plan-scope-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — Overview L11 contradicts dependency graph L110 on slice 1.7 independence

## Location

- `plan.md` Overview, **L11** — claims "slice 1.7 build tooling is fully independent of slices 1.1–1.6 and can ship last in parallel"
- `plan.md` Dependency Graph narrative, **L110** — documents the exceptions: "Slice 1.7 is otherwise independent of Slices 1.1–1.6 except that T39 depends on T25 for the defensive-copy site and on T21..."
- `plan.md` task list, **L92** — T39 `deps: [Task 21, Task 25]`

## What's wrong

The plan has an internal dependency contradiction: the Overview at L11 says
"slice 1.7 build tooling is fully independent of slices 1.1–1.6," but the
dependency graph at L110 and Task 39 metadata at L92 state T39 depends on
Task 21 (slice 1.4) and Task 25 (slice 1.5). This can mislead
sequencing/parallelization decisions at plan altitude — a parallelization
reader who stops at L11's overview statement would queue slice 1.7 as
fully parallel-eligible against slices 1.4 and 1.5.

## Suggested fix

Update the L11 Overview statement to reflect the explicit T39 cross-slice
dependencies (mirror or reference L110's qualified phrasing).
