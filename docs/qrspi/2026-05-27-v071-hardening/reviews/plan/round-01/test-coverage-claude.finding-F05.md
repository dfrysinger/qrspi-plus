# Finding F05: Task 5 — No expectation that existing inline `<!-- evergreen-exempt -->` markers are preserved

**Artifact:** plan.md
**Task:** Task 5 (G5 — evergreen-lint carve-out removal)
**Category:** Behavioral Coverage
**Severity:** advisory

## Problem

The task description states: "none of the five pre-existing violations that already carry inline markers are disturbed." This is a correctness invariant for the change — without it, the zero-violations result after carve-out removal could be achieved by accidentally or deliberately deleting the inline `<!-- evergreen-exempt -->` markers instead of relying on them.

However, no test expectation pins this constraint. The stated expectation is:

> "The evergreen scan executed against all repo-tracked markdown files reports zero violations…"

A test implementation that satisfies this expectation could pass even if all five inline markers were deleted (the scan would then report violations, but an implementation that re-marks them or silently deletes the prose instead of the marker would not be caught).

The structural test description ("verify that `_is_path_exempt()` contains no path-shaped `case` branches") guards the carve-out deletion but does not guard marker preservation.

## Recommendation

Add one expectation:

- "Each of the five files that previously depended on path carve-outs still contains at least one `<!-- evergreen-exempt -->` inline marker after the carve-out deletion (verified by file-content assertions in the structural test)."

Name the five files explicitly if known, or reference them by the count confirmed in `research/q07-codebase.md`.
