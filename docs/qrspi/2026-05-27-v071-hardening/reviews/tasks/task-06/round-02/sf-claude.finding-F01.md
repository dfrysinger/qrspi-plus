---
finding: F01
round: 2
reviewer: sf-claude
file: scripts/run-codex-review.sh
line: 148
change_type: correctness
severity: medium
title: Source guard `return 0` fails open on direct execution — set -e is disabled
---

## Summary

The source guard at line 148 uses `return 0` to short-circuit execution when
`QRSPI_SOURCE_ONLY=1` is set.  This works correctly when the file is *sourced*
(`. "$WRAPPER"`), because `return` is valid in that context.  But if the script
is *executed directly* (`bash run-codex-review.sh`) with `QRSPI_SOURCE_ONLY=1`
in the environment, `return` is invalid outside a function and outside a sourced
context, so bash emits an error and sets `$?=1`.  Because `set -e` is **not**
active (explicitly noted at line 50: "NOT -e"), the failed `&&` chain does not
abort the script — execution falls through to the argument-parsing block, and
the guard is silently bypassed.

## Relevant code

```bash
# line 49-51
set -u
# NOT -e: we want to surface validation errors with our own diagnostics.
# pipefail is off because the dispatcher handles its own error contract.

# line 148
[[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]] && return 0
```

## Failure mode

When both of the following conditions hold:

1. `QRSPI_SOURCE_ONLY=1` is present (e.g. leaked from a test harness or CI
   variable export into a production invocation).
2. The script is invoked as `bash run-codex-review.sh …` (not sourced).

…the guard silently fails to halt execution.  The script continues into
argument parsing.  In the common case (no valid flags supplied) it then exits
with a validation error, so the failure is *not* fully silent.  However, if a
caller happens to supply all required flags (e.g. a CI job that also sets
`QRSPI_SOURCE_ONLY=1` from a prior test step), the script runs a full real
dispatch — the opposite of the guard's intent — with no indication that the
guard was ineffective.

The bash error message ("can only `return' from a function or sourced script")
IS written to stderr, but only if the `[[...]]` condition is true; it does not
propagate as a non-zero exit from the `&&` chain in a way that halts the script.

## Fix options

Option A — Use an early-exit guard instead of `return` for non-sourced contexts:

```bash
# Replace the single-line guard with an if-block that works in both modes.
if [[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]]; then
  # If being sourced, return to the caller; if being executed, exit cleanly.
  # 'return' succeeds only when sourced; 'exit' is the fallback for executed mode.
  return 0 2>/dev/null || exit 0
fi
```

Option B — Detect sourced vs executed explicitly and only allow the guard in
sourced mode:

```bash
(return 0 2>/dev/null) && _sourced=1 || _sourced=0
if [[ "$_sourced" -eq 1 && "${QRSPI_SOURCE_ONLY:-}" == "1" ]]; then
  return 0
fi
```

Option A is simpler and bash-3.2 portable.

## Relation to task spec

Task 06 requires the guard to enable function-isolation tests that source the
script with `QRSPI_SOURCE_ONLY=1`.  The spec does not call out the executed-mode
failure, but the guard's stated purpose is to "return after loading function
definitions … without triggering argument parsing or validation."  The current
implementation only meets that contract in sourced mode.
