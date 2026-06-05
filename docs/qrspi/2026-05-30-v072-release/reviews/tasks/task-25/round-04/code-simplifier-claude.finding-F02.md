---
finding: F02
reviewer: code-simplifier-claude
round: 4
severity: advisory
category: verbose-patterns
---

# Compound `&&` assertion is non-idiomatic bats (8 occurrences in ordering tests)

**File:** `tests/unit/test-task-25-round03-fixes.bats`  
**Lines:** 64, 71, 78, 85, 94, 101, 108, 115 (one per ordering test)

## Current pattern

Every ordering test contains:

```bash
  [ -n "$begin_line" ] && [ -n "$cat_line" ]
```

## Why it's non-idiomatic

In bats (which runs under `set -e`), the standard guard pattern is two separate assertion lines:

```bash
  [ -n "$begin_line" ]
  [ -n "$cat_line" ]
```

The `&&` form works correctly — the compound command exits non-zero if either bracket test fails — but it has two drawbacks:

1. **Opaque failure message**: bats reports the compound line as the failing assertion without indicating *which* variable was empty.
2. **Style inconsistency**: everywhere else in the test file, each assertion occupies its own `[ ]` line. The `&&` form is the only exception across all 8 ordering tests.

## Suggested simplification

Replace each compound assertion with two separate lines:

```bash
  # Before (all 8 ordering tests):
  [ -n "$begin_line" ] && [ -n "$cat_line" ]

  # After:
  [ -n "$begin_line" ]
  [ -n "$cat_line" ]
```

This is a pure whitespace/layout change in behavior — both forms abort the test on the same conditions — but the two-line form produces a clearer failure message and matches the surrounding style uniformly.
