---
reviewer: silent-failure-claude
round: 3
finding: F01
severity: high
category: vacuous-test / silent-failure
file: tests/unit/test-plan-post-approval-split.bats
lines: 936–961
---

# F01 — SF04 multi-task HALT test: `dispatch_count` is never incremented → assertion is trivially true

## What the test claims to verify

`[split] Multi-task pre-fan-out HALT: single mismatch in 3-task set halts entire fan-out (zero dispatches)` (line 883) is the primary behavioral lock for the critical contract property:

> *"A single Case 3 mismatch anywhere in the set halts the **entire** fan-out."*

The test asserts `[ "$dispatch_count" -eq 0 ]` at line 961 to prove no sub-subagent dispatches fire, even for the two matching tasks (task-01 and task-03).

## Why it is vacuously true

`dispatch_count` is declared and initialised to `0` at line 937. Inside the for-loop (lines 940–954), the only state mutations are:

- `expected_hash` assignment (branch by task index)
- `continue` when the file is absent (Case 1 — never reached here because all 3 files exist)
- `mismatch_detected=true` when stored ≠ expected

There is **no code path that increments `dispatch_count`**. The assertion at line 961 evaluates `0 -eq 0` unconditionally, regardless of what the loop does. A re-implementation of the decision loop that counted dispatches for each matching task — the exact bug the test is supposed to prevent — would not change `dispatch_count` from zero because the increment is simply absent.

```bash
# Lines 936–961 (condensed)
local mismatch_detected dispatch_count …
mismatch_detected=false
dispatch_count=0                          # ← initialised to 0

for i in 1 2 3; do
  …
  if [ ! -e "$f" ]; then continue; fi     # absent → continue, no increment
  stored="$(grep … | awk …)"
  if [ "$stored" != "$expected_hash" ]; then
    mismatch_detected=true                # ← only state change
  fi
done

[ "$mismatch_detected" = "true" ]        # ← meaningful
[ "$dispatch_count" -eq 0 ]             # ← always 0, vacuous
```

## What IS covered (the meaningful assertions)

- `mismatch_detected = true` (line 957): the loop correctly detects task-02's stale hash. This is a real behavioral check.
- File content unchanged for all three tasks (lines 964–971): the loop does not touch any file. This IS meaningful.

## Risk

The contract's safety property is "if ANY task mismatches, **zero** dispatches fire for the whole set." Without an increment that could demonstrate a count > 0 in a broken implementation, no test currently exercises the "pre-fan-out scan defers all dispatch decisions until after the full scan" logic. An orchestrator that dispatches matching tasks first and only halts on hitting task-02 would pass this test.

## Remediation sketch

Either:

1. Split the decision loop into **scan** (sets `mismatch_detected`) then **dispatch** (increments `dispatch_count` only when `mismatch_detected = false`), so the dispatch phase never runs when mismatch is set:

   ```bash
   # After the scan loop above …
   if [ "$mismatch_detected" = "false" ]; then
     for i in 1 2 3; do
       f="…"; [ -e "$f" ] || dispatch_count=$((dispatch_count + 1))
     done
   fi
   [ "$dispatch_count" -eq 0 ]  # now non-vacuous: only true because mismatch halted dispatch phase
   ```

2. Or invert the proof: demonstrate that if `mismatch_detected = true` then the dispatch loop body is **not entered**, by structuring the dispatch increment inside an `if [ "$mismatch_detected" = "false" ]` gate.
