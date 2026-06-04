---
finding: F02
reviewer: code-quality-claude
round: 2
severity: minor
area: cleanliness
---

# F02 — Dead variable `original_mtime` in mismatch-HALT test

## Location

`tests/unit/test-plan-post-approval-split.bats`, test
`[T34-G5] Mismatch HALT: changed plan.md block with existing file halts and leaves file untouched`,
lines ~705–706 of the bats file (diff hunk lines 471–472):

```bash
local original_mtime
original_mtime="$(stat -f '%m' "$FIXTURE_DIR/tasks/task-01.md" 2>/dev/null || stat -c '%Y' "$FIXTURE_DIR/tasks/task-01.md" 2>/dev/null)"
```

## Problem

`original_mtime` is assigned but never read again in this test. The test uses
grep-based content assertions (`grep -F "# Task 1: original title"` etc.) to
verify the file is untouched, which is the correct approach; the mtime variable
adds no assertion and is dead code.

The platform-portability dual (`stat -f '%m' ... || stat -c '%Y'`) is non-trivial
boilerplate, which makes this particularly distracting for a reader trying to
understand the test's verification strategy.

## Fix

Remove the two lines. The content-comparison strategy already present in the test
is sufficient and more reliable than mtime comparison for a "file unchanged"
assertion.
