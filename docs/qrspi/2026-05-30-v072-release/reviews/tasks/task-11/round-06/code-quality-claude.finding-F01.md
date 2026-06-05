---
finding_id: F01
reviewer: code-quality-claude
model: claude-opus-4-5
round: 6
task: 11
severity: low
change_type: test-quality
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2786-2791
---

# code-quality-claude — task-11 round-06 — F01 (LOW)

## Vacuous-pass risk in `mktemp failure path` inspection test

**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, lines 2786–2791

The new inspection test:

```bash
@test "mktemp failure path in manifest append uses exit 1 not return 1" {
  local script="$REPO_ROOT/scripts/run-codex-review.sh"
  ! grep -A5 'mktemp failed for manifest tmp' "$script" | grep -qE '\breturn [0-9]' \
    || { echo "..."; return 1; }
}
```

passes vacuously if the anchor string `mktemp failed for manifest tmp` is not found in the
script — `grep -A5` returns no output, the downstream `grep -qE` exits 1 (nothing matched),
and `! (exit 1)` = true. The `||` branch never fires, and the test reports green even though
the intended coverage point is absent.

The developer was demonstrably aware of this failure mode: the R6 fix for the EXIT-trap test
(`split EXIT/INT/TERM traps so signals don't resume function`) includes an explicit guard:

```bash
[ -n "$exit_trap_line" ] \
  || { echo "ERROR: no EXIT trap found in script (expected a cleanup-only EXIT trap)" >&2; return 1; }
```

The same guard is missing here. If `_append_manifest_entry`'s mktemp error message is ever
rephrased, this test will silently lose its coverage without any test-failure signal.

### Suggested fix

Add a presence guard before the absence check:

```bash
@test "mktemp failure path in manifest append uses exit 1 not return 1" {
  local script="$REPO_ROOT/scripts/run-codex-review.sh"
  # Guard: anchor must exist so the absence check below is not vacuously true.
  grep -q 'mktemp failed for manifest tmp' "$script" \
    || { echo "ERROR: anchor 'mktemp failed for manifest tmp' not found in script" >&2; return 1; }
  # There must be no 'return N' within the mktemp failure block.
  ! grep -A5 'mktemp failed for manifest tmp' "$script" | grep -qE '\breturn [0-9]' \
    || { echo "mktemp failure path uses 'return N'; must use 'exit 1' consistent with all other error paths in _append_manifest_entry"; return 1; }
}
```
