---
finding_id: F02
reviewer: silent-failure-claude
round: 2
task: Task 5
category: SILENT_FALLBACK
severity: high
---

# F02 — Task 5: Structural assertion dropped; carve-out deletion unverifiable by CI

## Location

Task 5 test expectations — the structural code-pattern assertion that was present in round-01 and removed in round-02.

## What the round-01 plan said (removed in R2)

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no path-shaped `case` pattern branches after the modification.

## What the round-02 plan says instead

The test expectations now contain only scan-outcome assertions:

- The evergreen scan reports zero violations
- The five existing `<!-- evergreen-exempt -->` markers remain intact
- No new violations are introduced
- The jargon scan is unaffected
- The CI evergreen-lint job reports zero violations

## The silent failure

The five files that previously relied on path carve-outs **already carry** `<!-- evergreen-exempt -->` inline markers. This means the scan outcome is **identical** whether or not the carve-outs are deleted:

| Carve-outs present | Inline markers present | Scan result |
|-|-|-|
| yes | yes | zero violations ✓ |
| **no** | yes | zero violations ✓ |

All five test expectations in the current R2 spec will pass whether the implementer deletes the six `case` branches or leaves them entirely intact. An implementer who misreads the task, makes partial edits, or has a merge error that restores the branches will see green CI with no indication that the structural requirement was missed.

The task description still says *"All five path-shaped exemption groups (six `case` patterns total) are deleted"*, but there is no automated test that asserts this. The goal of the task—closing the silent-exemption surface permanently—is unverifiable by CI.

## Why this matters at runtime

If the carve-outs survive, path-based exemptions silently suppress violations for entire directory trees. The task exists specifically to close this silent-exemption hole. Without the structural assertion, future new violations introduced under an exempted path will silently pass the scan, defeating G5 entirely.

## Proposed fix

Restore the structural code-pattern assertion to the test expectations:

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no path-shaped `case` pattern branches after the modification (structural grep assertion against the test file itself, not against the scan output).

This is a different assertion from the scan-outcome assertions and tests a different condition. The design (DKR5) citing "CI-green is the enforcement surface" is accurate for the zero-violations outcome but does not cover the structural invariant that carve-outs are actually absent. Both assertions are needed.
