---
reviewer: code-quality-claude
phase: test
round: 01
severity: minor
change_type: defect
finding_id: F04
title: test-g6 discards `git merge` exit status with `>/dev/null 2>&1`, masking conflict failures and producing misleading downstream assertions
files:
  - tests/acceptance/v07-phase1-test-phase/test-g6-stage-commit-parents.bats
---

## What

Lines 69 and 84 of `test-g6-stage-commit-parents.bats`:

```bash
git merge --no-ff -m "stage W2" task-A task-B >/dev/null 2>&1
```

Both stdout AND stderr are redirected to `/dev/null` AND the exit status is not checked (`run`-wrapped, no following `[ "$status" -eq 0 ]`, or bare invocation with no `||` guard).

## Why it matters

- **Conflict path is silent.** If a future fixture change (or a git version difference, or an unusual default-branch config like `init.defaultBranch=master` vs `main`) causes the octopus merge to hit a real conflict, the merge fails, no stage commit is created, but the test proceeds to `run "$VSCP" --validate ...`. The subsequent assertion `[ "$status" -eq 0 ]` (line 73) might pass or fail in confusing ways — and the diagnostic is fully swallowed because stderr is discarded too.

- **The boundary test (line 84) is worse.** Its premise is "merge BOTH task tips though only task-A was captured" — if that merge silently fails, the `--validate` call wouldn't see an extra parent because no merge commit exists at all, and the test still expects status≠0 from `--validate`. It might pass for the wrong reason (e.g. validate complains about the stage SHA not being a merge commit at all, with a different diagnostic than `stage-commit-parent-mismatch`), or fail in a way that takes hours to debug because stderr from the merge was thrown away.

- **`run` is the established idiom in this very file** (used elsewhere for `$VSCP` invocations). It would surface the merge's stderr in `$output` automatically.

## Recommended fix

```bash
run git merge --no-ff -m "stage W2" task-A task-B
[ "$status" -eq 0 ] || {
  echo "stage merge failed unexpectedly; output:" >&2
  echo "$output" >&2
  false
}
```

Or, for the boundary test where merge success is also the precondition, the same `run` + status-check.

## Verification

- Force a merge conflict (e.g. both task branches modify the same line) and confirm the test now fails with a clear `stage merge failed unexpectedly` diagnostic instead of a confusing downstream `[ "$status" -eq 0 ]` failure.
