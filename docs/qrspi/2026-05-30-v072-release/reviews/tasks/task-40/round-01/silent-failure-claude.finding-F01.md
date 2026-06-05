---
reviewer: silent-failure-claude
task: 40
round: 1
finding: F01
severity: medium
category: vacuous-lint / silent-fallback
file: tests/unit/test-ci-workflow-shape.bats
lines: 380-390
---

# F01 — Pre-commit-hook prohibition pin is vacuous in CI

## What

The `[T40/G21] no pre-commit hook script for G21 body-guard rule` test is
intended to enforce G21 sub-decision C1 ("CI gate only; no pre-commit hook").
As written, it can never fail in the blocking CI environment, and silently
under-covers a chunk of the surface its own comment names.

```bash
@test "[T40/G21] no pre-commit hook script for G21 body-guard rule" {
  require_repo_root
  # G21 sub-decision C1: CI gate only; no pre-commit hook.
  # A .git/hooks/pre-commit or scripts/pre-commit* would be a C1 violation.
  local hooks_dir="$REPO_ROOT/.git/hooks"
  if [ -f "$hooks_dir/pre-commit" ]; then
    run grep -E 'body.guard|bats-body-assertion' "$hooks_dir/pre-commit"
    [ "$status" -ne 0 ]
  fi
}
```

Two silent-failure surfaces:

1. **`.git/hooks/pre-commit` is per-clone, not tracked.** On a fresh CI
   checkout the file does not exist, so the `if [ -f ... ]` guard short-
   circuits to a vacuous pass. The pin can only ever fire on a developer's
   own workstation, never on the blocking path. As a C1 enforcement gate in
   CI this is effectively a no-op.

2. **The comment promises `scripts/pre-commit*` coverage that the test
   does not implement.** A committed shim under `scripts/pre-commit-body-guard`
   (or a `.husky/pre-commit`, `lefthook.yml`, etc.) wiring the G21 lint into
   a local hook would land in the repo, satisfy the docstring's example
   ("`scripts/pre-commit*` would be a C1 violation"), and pass this test
   without ever being checked. Anyone reading the test name / comment will
   reasonably assume it is enforced.

## Why this matters

This is a classic vacuous-lint / silent-fallback: the test is GREEN in the
exact environment where it claims to enforce the rule, so a C1 violation
landing in the repo would be discovered only by code review, not by the
gate the task installs to prevent that.

## Suggested resolution

Either:

- Drop the test (and document that C1 is review-enforced, not pin-enforced),
  so the test suite does not advertise an enforcement that does not exist;
  or
- Make the pin actually load-bearing in CI by checking the **committed**
  surface: e.g., assert that no tracked file under `scripts/`, `.husky/`,
  `.githooks/`, or `lefthook.*` references `body-guard` /
  `bats-body-assertion`. That would fail loudly in CI if a C1 violation
  were merged.
