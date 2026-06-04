---
finding: F03
reviewer: code-simplifier-claude
round: 7
file: tests/unit/test-detect-interaction-mode.bats
lines: "402-404, 415-417, 647-649, 667-669"
category: Verbose Patterns
severity: advisory
blocking: false
---

# F03 — 4-way verbatim repetition of the `find|wc|tr` file-count block

## Location

`tests/unit/test-detect-interaction-mode.bats`:
- Lines 402–404 (`[T24] Copilot CLI branch creates no .interaction-mode-audit.json`)
- Lines 415–417 (`[T24] Unknown host branch creates no files at all`)
- Lines 647–649 (`Claude Code branch creates no files at all`)
- Lines 667–669 (`Override branch creates no files at all`)

## Pattern observed

Each of the four no-file-write tests ends with this identical block:

```bash
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
```

The three-step pipeline (`find | wc -l | tr -d ' '`) and the
intermediate variable are identically repeated in all four locations.

## Why it matters

All four blocks are semantically identical.  Any future change to the
detection logic (e.g. switching to `find … | wc -l` with a different
flag, or using `ls -A` instead) must be made in four places, and a
copy-paste error would leave the suite silently inconsistent.

## Proposed fix

Define a one-line helper function in the suite preamble (before the
first `@test`) and call it from each test:

```bash
# ---------------------------------------------------------------------------
# Suite helpers
# ---------------------------------------------------------------------------

_assert_tmpdir_empty() {
  # Fails (non-zero) if any regular file exists directly under $1.
  local n
  n="$(find "$1" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n" -eq 0 ]
}
```

Then each test body becomes:

```bash
# before:
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]

# after:
  _assert_tmpdir_empty "$tmpdir"
```

All four no-file-write tests shrink by 2 lines each; the logic lives in
exactly one place; and the test name `_assert_tmpdir_empty` is
self-documenting.  No test behavior changes.
