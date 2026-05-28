---
finding_id: F01
round: 2
reviewer: test-coverage-claude
severity: high
task: Task 5
category: behavioral_coverage
status: open
---

# F01 — Task 5: All test expectations pass whether or not carve-outs are removed

## Problem

The R2 diff removes the only test expectation that directly verifies the primary code
change in Task 5 — the `_is_path_exempt()` structural assertion. The replacement
expectations are all satisfied regardless of whether the implementer removes the
path-shaped `case` branches or not.

**Removed expectation (R1):**
> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no
> path-shaped `case` pattern branches after the modification

**The logic gap:** Design DKR5 confirms that all five current evergreen violations
already carry `<!-- evergreen-exempt -->` inline markers. This means the evergreen scan
produces **zero violations in both states**:
- State A (carve-outs present, inline markers present): zero violations — paths are
  exempted by path carve-outs before the inline check runs
- State B (carve-outs removed, inline markers present): zero violations — paths reach
  the inline check and are suppressed there

Every remaining test expectation in Task 5 is satisfied under State A:

| Expectation | Passes with carve-outs intact? |
|---|---|
| Evergreen scan reports zero violations | ✓ Yes |
| Five `<!-- evergreen-exempt -->` markers remain intact | ✓ Yes (they were never touched) |
| No new violations introduced | ✓ Yes |
| Jargon scan unaffected | ✓ Yes |
| CI reports zero violations | ✓ Yes |

An implementer can submit a PR that makes **no change at all** to
`tests/unit/test-evergreen-markdown.bats` and every stated test expectation will pass.
The task's deliverable — removal of path-shaped carve-outs — becomes completely
unverifiable.

## Supporting Evidence

From design.md DKR5 (emphasis added):
> "disabling carve-outs while **leaving inline markers active produces zero violations**"

The zero-violations outcome is identical in both states; a test that produces the same
result under both pass and fail conditions is not a test.

The phasing.md replan-gate criterion 4 says "the evergreen-lint scan runs across the full
repo **with all path carve-outs removed**" — but none of the Task 5 test expectations
verify that the carve-outs were actually removed.

## Required Fix

Restore a structural assertion verifying the carve-outs are absent. This was correctly
specified in R1 and should not have been dropped. The correct form is:

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no
> path-shaped `case` pattern branches after the modification (structural grep assertion;
> RED when any `case` pattern matching a path-prefix or glob appears in the function
> body, GREEN after the six patterns are deleted)

The zero-violations assertions are acceptable as additional confirmatory checks, but they
cannot substitute for this structural assertion because they are not falsified by the
change being absent.
