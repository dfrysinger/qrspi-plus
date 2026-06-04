---
finding: F02
reviewer: code-quality-claude
round: 4
severity: minor
area: id-hygiene
---

# F02 — QRSPI-internal IDs T31/T32 in newly-added code comment

## Location

`tests/unit/test-plan-post-approval-split.bats`, lines 36–41 (R4 diff, `+` lines 55–62).

The R4 diff adds this block:

```bash
# Test-name tag conventions used in this file:
#   [T32-split] — pre-existing T31/T32 tests covering the dispatch contract
#       structure (input payload, atomicity, exact-set verification). Do not
#       extend this prefix in new work.
#   [split]    — current canonical prefix. All new tests covering the
#       block-hash idempotency contract, pre-fan-out HALT, Task-ID validation,
#       and approval-state completion use this prefix. Add new tests under
#       this tag.
```

## What the rule says

Per the ID Hygiene review criteria (§11), QRSPI-internal IDs — G/R/D/T/Q-prefixed numeric tokens — are **forbidden in code comments** outside `docs/qrspi/`, regardless of how scoped the comment is.

The tokens `T31` and `T32` in the phrase `pre-existing T31/T32 tests` are QRSPI-internal T-prefixed numeric identifiers embedded in a code comment in a `.bats` file.

## Why the restriction applies

The test tag prefix `[T32-split]` was established before this task; its presence in existing `@test` names is pre-existing and outside R4's diff surface. However, the R4 diff **introduces a new comment** that explains the tag's origin by citing `T31/T32` in prose. The comment is in the diff and the IDs appear in a `#` comment line in the production test file — that is the flagged surface.

## Remediation

Replace the task-ID references with behavior-based descriptions:

```bash
# Test-name tag conventions used in this file:
#   [T32-split] — legacy prefix on pre-existing tests covering the dispatch
#       contract structure (input payload, atomicity, exact-set verification).
#       Do not extend this prefix in new work.
#   [split]    — current canonical prefix. All new tests covering the
#       block-hash idempotency contract, pre-fan-out HALT, Task-ID validation,
#       and approval-state completion use this prefix. Add new tests under
#       this tag.
```

This preserves the full orientation value of the comment without embedding QRSPI-internal identifiers.
