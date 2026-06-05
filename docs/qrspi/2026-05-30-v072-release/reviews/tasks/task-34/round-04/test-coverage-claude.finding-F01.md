---
finding_id: R4-F01
reviewer_tag: test-coverage-claude
round: 4
task: 34
severity: minor
change_type: test_coverage
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

# F01 — Quick-fix N=1 safe-skip test omits content-unchanged assertion

## Location

`tests/unit/test-plan-post-approval-split.bats`, lines 858–878.

## What the test does

The test `[split] Quick-fix N=1 path: re-run with matching hash is a safe-skip` seeds a task-01.md with a valid block-hash, recomputes the hash from the same source block, reads the stored hash from the file, and asserts `stored == recomputed`. It stops there.

## What is missing

The "safe-skip" property has two observable components:

1. The hash match is detected (tested — `stored == recomputed`).
2. The file body is not rewritten (NOT tested).

The analogous general hand-edit test at lines 665–692 asserts both components:

```bash
[ "$stored_hash" = "$recomputed_hash" ]
grep -F "This note was added by hand..." ...
```

A regression where the N=1 path rewrites the file on hash match — overwriting hand-edits — would not be caught by the current quick-fix safe-skip test.

## Why it matters

The task-34 test expectation states the quick-fix path applies "the same absent, match, mismatch, missing-header, and malformed-header audit rules." The "match → safe-skip without rewrite" rule has two behavioral outputs. Only the first is asserted for the N=1 path.

## Remediation (informational — budget exhausted, accepted-with-issues)

Add a `content_before` capture before the decision logic and a `content_before == content_after` assertion after:

```bash
local content_before
content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
# ... existing hash-match assertions ...
local content_after
content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
[ "$content_before" = "$content_after" ]
```
