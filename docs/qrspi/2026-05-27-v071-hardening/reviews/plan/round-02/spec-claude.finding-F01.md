---
finding_id: F01
severity: major
task: Task 5
goal_ids: [G5]
category: test-coverage-gap
round: 2
---

# F01 — Task 5 has no RED-phase test expectation for the core G5 deliverable

## Summary

All five test expectations in Task 5 pass in the **current (pre-task) state** — carve-outs present
plus inline markers present already yields zero violations. There is no expectation that fails RED
before the carve-outs are deleted and passes GREEN after. This means the specific deliverable of
Task 5 (removing the six `case` branches from `_is_path_exempt()`) is not independently verifiable
by any plan-authored test expectation.

## Detail

**Goal:** G5 requires that "the evergreen scan covers its intended surface unconditionally — no
directory tree is silently exempted by path." The goal's success condition is that the path-shaped
case branches are actually removed, not merely that violations are already handled by inline markers.

**Current test expectations (all pass in current state):**
1. "The evergreen scan executed against all repo-tracked markdown files reports zero violations" —
   passes today (carve-outs + inline markers → zero violations); passes after deletion (no
   carve-outs + inline markers → zero violations). No differentiation.
2. "The five existing `<!-- evergreen-exempt -->` inline markers remain intact" — passes today
   and after deletion.
3. "No new violations are introduced by the removal of the carve-out groups" — same as (1).
4. "The jargon scan is unaffected" — already true; unaffected by carve-out deletion.
5. "The existing evergreen-lint job in CI reports zero violations after carve-out removal" —
   also passes without the deletion because inline markers suppress violations.

None of these expectations would fail on the current codebase. The test-writer has nothing to write
in RED for Task 5. Without a RED-phase assertion, the RED-verification gate between test-writer and
implementer is effectively absent for this task.

**Context:** Round 1 included this expectation that WAS RED-verifiable:

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no path-shaped `case`
> pattern branches after the modification

This was dropped in Round 2. Design DKR5 says "No new test code — the existing evergreen-markdown
unit test is the test." However, DKR5 also notes "Assertion text, full test procedures, and
per-task-file layout are deferred to Plan," and design DKR5's scope is the *test file* (no new
file), not the prohibition of new assertions in the existing file. A structural pattern check
against `_is_path_exempt()` added to `tests/unit/test-evergreen-markdown.bats` is an assertion in
the existing file, consistent with DKR5's letter.

## Required Fix

Add one test expectation to Task 5 that is RED on the current codebase and GREEN after the task:

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no `case` pattern
> branch whose value is a path-shaped string (i.e., contains `/`, matches `docs/*`, `CHANGELOG.md`,
> or equivalent) after the modification — verified by a structural grep/awk scan of the function
> body in the bats file itself.

This expectation fails RED today (six `case` branches are present) and passes GREEN after deletion.
It is an assertion in the *existing* test file, consistent with DKR5. It is the only plan-authored
expectation that directly verifies the specific G5 deliverable.

## Why This Matters

Without this expectation, an implementer who removes zero lines from `_is_path_exempt()` (leaves
the carve-outs intact) would pass all Task 5 test expectations. The goal's stated invariant —
"no directory tree is silently exempted by path" — becomes unverifiable at the task boundary and
can silently regress in future work that adds a new path carve-out for a directory that has no
current violations.
