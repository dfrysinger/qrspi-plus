---
title: "FIXTURE_DEST assignment has no error guard — silent failure leaves sandbox check neutered"
finding_id: R2-F01
severity: high
change_type: correctness
file: tests/unit/test-change-type-partition.bats
line: 235
category: silent-failure
round: 2
reviewer: silent-failure-claude
---

## Description

The R2 rewrite of `_run_fan_in_on_fixture` adds a `FIXTURE_DEST` variable for
symlink-resolved path comparison (macOS `/var` → `/private/var`), but the
assignment is not guarded against failure:

```bash
# line 235
FIXTURE_DEST="$(cd "$dest" && pwd -P)"
```

In bash, a variable assignment of the form `VAR=$(subshell)` **does not**
propagate the subshell's exit code to the outer shell. If `cd "$dest"` fails
(race between `mktemp -d` and `cd`, a permission change, a stale tmpdir from
a previous run, etc.) the `&&`-chained `pwd -P` is skipped, the command
substitution exits non-zero *inside the subshell*, and `FIXTURE_DEST` is
assigned an **empty string**. The function then falls through and **returns 0**.

### Why callers do not catch this

Every call site was hardened in R2 with:

```bash
_run_fan_in_on_fixture ... \
  || { echo "fixture setup failed (exit $?)"; return 1; }
```

That guard fires only on a non-zero return from the helper. Because the helper
returns 0, all three call sites proceed without a diagnostic.

### Downstream silent-failure effect

`FIXTURE_DEST=""` propagates into the sandbox check at line 304:

```bash
[[ "$p" == "$FIXTURE_DEST"/* ]]
```

When `FIXTURE_DEST` is empty, the right-hand operand expands to `/*`. In a
bash `[[ ]]` compound command, an **unquoted** `*` on the right of `==` is
treated as a glob wildcard. `/*` therefore matches **any string beginning with
`/`**, i.e. every absolute path on the system. The defense-in-depth bound
described in the comment ("keep awk parsing inside the sandbox") is completely
neutered: the `while IFS= read -r p` loop at lines 303–310 will awk-parse
*any* path written into `kept-findings.txt`, including paths outside
`$BATS_TEST_TMPDIR`.

### Correct fix

Add an explicit error guard, mirroring the `mktemp` and `cp -R` lines above:

```bash
FIXTURE_DEST="$(cd "$dest" && pwd -P)" \
  || { echo "pwd -P failed for $dest" >&2; return 95; }
```

Or, equivalently, check `[[ -n "$FIXTURE_DEST" ]]` immediately after the
assignment and return with a diagnostic if it is empty.

## Evidence

Line 235 of the current worktree HEAD (05049d0):

```
FIXTURE_DEST="$(cd "$dest" && pwd -P)"
```

The `mktemp` line above it (218–219) and the `cp -R` line (223–224) both use
`|| { ...; return N; }` guards. This line does not.
