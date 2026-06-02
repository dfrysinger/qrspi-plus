---
finding_id: R5-F01
reviewer_tag: test-coverage-codex
round: 5
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# T16 scope claims dispatch-order preservation but Test Expectations include no ordering assertion

## What

Task 16 scope (plan.md line 990) requires preserving the TDD dispatch order (test-writer first, implementer second after RED verification). The Test Expectations block (lines 1013-1023) covers routing precedence, none-tier halt, same-vendor halt, schema validation, tier sweep, and co-escalation, but no ordering check.

## Why it matters

Scope explicitly requires order preservation at line 990. If the order can silently regress (e.g., dispatch refactor accidentally reverses), no test in the plan would catch it. A test-writer-after-implementer order defeats TDD (the implementer would write code against no failing test).

## Suggested fix

Add a Task 16 test expectation that asserts dispatch sequencing remains test-writer-before-implementer with the RED gate in between (e.g., via a targeted unit/integration fixture over the implement dispatch flow).
