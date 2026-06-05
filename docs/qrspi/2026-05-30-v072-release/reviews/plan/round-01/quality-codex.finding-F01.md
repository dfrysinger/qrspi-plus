---
finding_id: R1-F01
reviewer_tag: quality-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 29, Task 37, Task 38 — Target files sets vs structure.md required files"
---

## Issue

`structure.md` requires three files that are not owned by any Plan task: `skills/structure/owns-defers.md`, `tests/lint/test-design-altitude-boundary-include.bats`, and `tests/lint/test-structure-altitude-boundary-include.bats`. Task 29, 37, and 38 are the natural homes for these files but none enumerate them in their Target files sets.

## Why

A file required by structure but unclaimed by any task will not be written — the implementer's contract is the task's Target files set, not the structure inventory. Each goal-level coverage check would pass while the actual disk surface ships incomplete.

## Fix

Audit structure.md's per-file blocks against the union of all Plan Target files sets; assign each unclaimed file to a single task. For these three: add `skills/structure/owns-defers.md` to T29; add the two `tests/lint/test-*-altitude-boundary-include.bats` to T37 (design) and T38 (structure).
