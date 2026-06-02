---
finding_id: R1-F03
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 26 (~lines 1592-1649)"
---

## Issue

T26 bundles multiple independent observable changes (Design `include::` directives, Plan SKILL classification rewrite, Plan dispatch payload changes, 3+ agent contract updates) without a `sizing_exception` declaration.

## Why

Atomicity/sizing guidance treats each independent observable change as a separate task unless a sizing_exception is declared. Without the exception, T26 is over-bundled — hard to review, hard to roll back, and concurrent implementer work on the bundled surfaces will conflict.

## Fix

Either (a) add a `sizing_exception` with rationale, or (b) split T26 into atomic sub-tasks:
- T26a: Design + Plan SKILL include/classification changes
- T26b: agent preload updates (implementer-lightweight, design-reviewer)
- T26c: plan-test-coverage-reviewer Rule C / lightweight-skip contract
