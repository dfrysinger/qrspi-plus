# F01 — Stale comment enumerating path prefixes diverges from regex

**Category:** Readability / Inconsistency
**Severity:** nit
**File:** `tests/unit/test-ci-workflow-shape.bats:380–393`

## Current

```bats
@test "[T40/G21] no tracked hook script wires body-guard or bats-body-assertion (C1 enforcement)" {
  require_repo_root
  # G21 sub-decision C1: CI gate only; no pre-commit hook.
  # Assert no tracked file under scripts/, .husky/, .githooks/, or lefthook.*
  # references body-guard or bats-body-assertion. ...
  ...
  done < <(git -C "$REPO_ROOT" ls-files | grep -E '^(scripts|\.husky|\.githooks|lefthook|\.pre-commit-config|\.pre-commit-hooks)')
```

The R3 fix adds `.pre-commit-config` and `.pre-commit-hooks` to the prefix
regex (which is exactly the right move — the C1 sub-decision is "no
pre-commit hook," so the scan must cover pre-commit's well-known config
file paths). However, the explanatory block comment two lines up still
enumerates only `scripts/, .husky/, .githooks/, or lefthook.*`. A reader
auditing this assertion will see a four-prefix list in prose and a
six-prefix list in the actual regex, and have to reconcile the
discrepancy — exactly the kind of friction that erodes trust in
hook-prevention assertions.

## Suggested simplification

Update the comment so the prose list matches the regex:

```bats
  # Assert no tracked file under scripts/, .husky/, .githooks/, lefthook.*,
  # .pre-commit-config.*, or .pre-commit-hooks.* references body-guard or
  # bats-body-assertion. ...
```

Pure documentation alignment; no behavior change. This is the only
simplification opportunity in the R3 diff — the regex extension itself
is the minimal possible fix for the R2/F01 finding it addresses.

## Behavior preservation

Comment-only edit; semantics unchanged.
