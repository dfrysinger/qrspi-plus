---
finding: F01
reviewer: gt-claude
round: 9
task: task-01
severity: low
change_type: clarity
file: tests/unit/test-run-third-party-llm.bats
lines: [543]
---

# Stale line-number cross-reference in newly authored NUL-case comment

## Location

`tests/unit/test-run-third-party-llm.bats` line 543 (inside the NUL arm of the
`parametric: every C0 byte … in header VALUE causes exit` test, added in R8):

```bash
        # NUL: bash strips it at variable assignment; must use raw fixture
        # pre-flight scan — the same approach as Bullet 6 (line 560).
```

## Problem

The comment was authored with `(line 560)` as a navigation hint to the Bullet 6
NUL-in-value test.  Before the R8 parametric blocks were inserted, that test was
near line 560.  After R8 prepended ~182 lines of parametric code ahead of Bullet 5
and 6, the Bullet 6 test now opens at **line 736** in the HEAD file.  The reference
is immediately stale as delivered.

## Traceability impact

The comment does not contradict any spec language and has no effect on test
correctness or the Bullet 1 → G1 traceability chain.  However, a developer
following the `(line 560)` pointer will land in the middle of the LF
function-extraction path (the LF VALUE parametric case) rather than the Bullet 6
NUL-sentinel test, obscuring the intent of the NUL comparison.

## Recommended fix

Update the parenthetical to the current line number, or drop the fragile line
reference and use the test-name anchor instead:

```bash
        # NUL: bash strips it at variable assignment; must use raw fixture
        # pre-flight scan — the same approach as the dedicated Bullet 6 test
        # ("[control-char-detect] NUL (0x00) in header value causes exit …").
```
