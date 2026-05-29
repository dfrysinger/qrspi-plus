---
reviewer: simplify-claude
task: 8
round: 1
severity: low
blocking: false
category: inconsistency
file: tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats
lines: 147,155
---

# F02 — Two distinct @test cases share the same `[T8 / TE9b]` tag

## Observation

The new acceptance file declares two distinct `@test` blocks both tagged `[T8 / TE9b]`:

- Line 147: `@test "[T8 / TE9b] tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains no run_pin invocations referencing the deleted capability-gate suite"`
- Line 155: `@test "[T8 / TE9b] tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains no run_pin invocations referencing the deleted cache-hit-rate suite"`

These pin two different deletions (`test-cache-control-capability-gate.bats` and `test-cache-hit-rate.bats`). The TE-tag convention everywhere else in the file is one tag per test (TE1, TE2, TE3, TE4, TE5×3, TE8, TE9a, TE10a, TE10b). Reusing TE9b breaks the tag→test bijection that makes the rest of the file easy to grep through.

Comparable cases in the same file split into `a` / `b` suffixes (TE9a + TE9b ; TE10a + TE10b) and TE5 splits into three identically-tagged tests but they all assert the same expectation against the same file (three literals in `SKILL.md`) — a defensible exception because TE5 itself is a multi-literal expectation. The two TE9b tests, by contrast, assert two structurally different deletion claims.

## Why it matters

When CI reports a failure as `[T8 / TE9b] ... contains no run_pin invocations ...`, the grep tag alone no longer locates a unique test in source — the operator must read further into the name to disambiguate. Tag-prefix discipline is one of the affordances this file is buying with its careful `[T8 / TE<N>]` scheme.

## Suggested fix

Rename one of the two: most natural is

- `[T8 / TE9b]` → keep for capability-gate suite assertion (line 147)
- `[T8 / TE9b]` → `[T8 / TE9c]` for cache-hit-rate suite assertion (line 155)

Or, if the intent is to keep them grouped under TE9b (single test expectation broken into two assertions), split with `b1`/`b2` suffixes. Mechanical edit; no impact on bats behavior, only on tag uniqueness.

Non-blocking — suggestion only.
