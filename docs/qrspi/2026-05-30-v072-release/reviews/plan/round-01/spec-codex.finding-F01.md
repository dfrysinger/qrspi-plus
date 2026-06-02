---
finding_id: R1-F01
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 42 Target files (~lines 2568-2581)"
---

## Issue

T42 Target files declares `tests/unit/test-agent-frontmatter-no-model.bats (or ... successor ...)` and includes "locate the current owner..." prose. The target path is conditional/discovery-dependent rather than a single concrete file.

## Why

A task whose Target files is conditional cannot be reviewed or implemented atomically: discovery happens during execution, and the actual disk surface is unknown at plan time. The Definition of done becomes non-deterministic.

## Fix

Lock one concrete target path for v0.7.2 (resolve against structure.md now), or split T42 into a discovery/update-structure task (T42a) followed by a fixed-path implementation task (T42b).
