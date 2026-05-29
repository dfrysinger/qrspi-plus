---
reviewer: silent-failure-claude
task: 2
round: 1
finding: F01
severity: minor
category: silent-fallback
file: tests/unit/test-commit-hygiene-invariants.bats
lines: "277-282"
status: open
---

# F01 — Vacuous-pass risk from negative-only assertion in fresh-clone simulation test

## Location

`tests/unit/test-commit-hygiene-invariants.bats`, lines 277–282 (diff hunk lines 75–81):

```bash
  local staged
  staged="$(git -C "$fresh_dir" diff --cached --name-only)"
  rm -rf "$fresh_dir"
  # The scratch file must NOT appear in the staged index. ...
  ! printf '%s\n' "$staged" | grep -E "^\.qrspi-commit-msg\.txt$"
```

## What goes wrong

The test asserts only the **negative** condition: the scratch file path is absent
from the staged index. There is no **positive** assertion confirming that the
staging step actually captured something meaningful (e.g., that `work.txt` is
present in `staged`).

If `git add -A` exits 0 but stages nothing — due to a git version quirk, an
unexpected working-directory mismatch, or an edge case in `git init` flag
handling — `staged` will be empty (or contain only `.gitignore`). In that
scenario:

```
! printf '' | grep -E "^\.qrspi-commit-msg\.txt$"
```

passes trivially because an empty string can never match the pattern. The test
returns green without having verified that the `.gitignore` protection actually
prevented staging.

This is a **silent false pass**: the test signals success even though the core
invariant (`.gitignore` blocks staging) was never exercised.

## Why the risk is real

`git add -A` does not fail with a non-zero exit when it simply has nothing new
to add beyond what's already staged. If an earlier step (e.g., the base-commit
`git add base.txt` inadvertently staged `work.txt` as well, or if the fixture
directory layout differed) left the working tree with no unstaged changes,
`git add -A` would exit 0 with no new entries. The subsequent
`diff --cached --name-only` would then return only `base.txt` (already committed)
or nothing at all, and `staged` would appear empty.

## Recommendation

Add a positive assertion **before** the negative one to confirm that the staging
step captured at least `work.txt`:

```bash
  local staged
  staged="$(git -C "$fresh_dir" diff --cached --name-only)"
  rm -rf "$fresh_dir"
  # Positive guard: staging must have captured work.txt, proving git add -A ran.
  printf '%s\n' "$staged" | grep -qE "^work\.txt$" \
    || { printf 'FAIL: staging captured nothing — test is vacuous\n' >&2; return 1; }
  # The scratch file must NOT appear in the staged index.
  ! printf '%s\n' "$staged" | grep -E "^\.qrspi-commit-msg\.txt$"
```

This converts the silent vacuous pass into a visible failure whenever the
staging step does not execute as expected.

## Secondary issue — `fresh_dir` not cleaned up on mid-test failure

`fresh_dir` is created via `mktemp -d` but only removed with `rm -rf "$fresh_dir"`
on the happy path. If any intermediate command (between line 249 and line 278)
fails and causes bats to abort the test, the temp directory leaks. The test's
`teardown()` only removes `$FIXTURE_DIR`. This is minor (OS will reclaim
`/tmp` eventually), but adding a bats `trap` or a conditional `rm -rf` in an
`on_failure` hook would be cleaner.
