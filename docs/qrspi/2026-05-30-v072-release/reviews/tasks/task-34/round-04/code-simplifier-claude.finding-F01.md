---
finding: F01
reviewer: code-simplifier-claude
round: 4
severity: advisory
category: Dead Code (computed but never-read variables)
---

# F01 — `hash01_current` / `hash03_current` computed but never compared

## File and lines

`tests/unit/test-plan-post-approval-split.bats`  
Lines ~962–965 (scan-phase setup in the multi-task pre-fan-out HALT test)

## Current pattern

```bash
local hash01_current hash02_current hash03_current
hash01_current="$(printf '### Task 1: first\nbody01\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
hash02_current="$(printf '### Task 2: second-amended\nAmended body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
hash03_current="$(printf '### Task 3: third\nbody03\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
```

In the scan loop (lines ~991–1005), `expected_hash` is set from one of the three variables at the top of each iteration, but for `i=1` and `i=3` the file is absent so `continue` fires **before** `expected_hash` is ever read in a comparison:

```bash
if [ ! -e "$f" ]; then
  absent_ids+=("$i")
  continue          # ← expected_hash was just assigned; never used
fi
stored="$(grep -E "^# block-hash:" "$f" | awk '{print $3}')"
if [ "$stored" != "$expected_hash" ]; then   # only reached for i=2
  mismatch_detected=true
fi
```

`hash01_current` and `hash03_current` are therefore **written but never read**. Only `hash02_current` participates in the actual comparison that sets `mismatch_detected=true`.

## Proposed simplification

Drop the two unused variables and the loop's dead assignments:

```bash
# Only task-02's current hash is needed; task-01 and task-03 are absent.
local hash02_current
hash02_current="$(printf '### Task 2: second-amended\nAmended body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
```

And simplify the `expected_hash` assignment inside the loop:

```bash
for i in 1 2 3; do
  f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
  if [ ! -e "$f" ]; then
    absent_ids+=("$i")
    continue
  fi
  stored="$(grep -E "^# block-hash:" "$f" | awk '{print $3}')"
  # Only task-02 is on disk in this fixture; no need to branch on i.
  if [ "$stored" != "$hash02_current" ]; then
    mismatch_detected=true
  fi
done
```

## Why this is safe

The test intent — prove that a single Case 3 mismatch (task-02) halts the entire fan-out even when Case 1 absent tasks (task-01, task-03) would otherwise dispatch — is unchanged. `mismatch_detected` is driven only by the task-02 comparison; removing the unused variables and the unreachable `expected_hash` branches does not alter any assertion.
