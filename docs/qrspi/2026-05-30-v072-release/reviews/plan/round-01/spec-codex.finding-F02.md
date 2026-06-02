---
finding_id: R1-F02
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 43 (~lines 2626, 2641, 2648, 2666)"
---

## Issue

T43 uses conditional file scope: `test-using-qrspi-routing-block.bats if present after Task 42` and "re-audit post-T42 tree". Same shape as F01 — task contract is not fixed at planning time.

## Why

Same determinism problem as F01. T43's actual file surface depends on a runtime check after T42 completes.

## Fix

(a) Enumerate exact existing files now using the current test-surface inventory; or (b) split into a first task that reconciles live test-surface inventory and a second task that does fixed-path dedup.
