---
finding_id: F01
reviewer: goal-traceability-claude
round: 2
severity: medium
artifact: plan.md
section: "Task 5: Remove path-shaped exemption groups from evergreen-lint helper"
checklist_item: "1. Forward Trace — Goals to Tasks (partial coverage flag)"
---

# F01 — G5 test expectations are non-discriminating: core structural change is unverifiable

## Problem

The round-2 change to Task 5 removed the one test expectation that would structurally
verify the G5 deliverable. The remaining expectations are satisfiable without the core
change (branch deletion) actually happening.

**G5 goal (from `goals.md`):** Delete the five path-shaped exemption groups from
`_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` so the evergreen scan
covers its intended surface unconditionally.

**Round-1 test expectation (removed in round 2):**

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no
> path-shaped `case` pattern branches after the modification

**Current Task 5 test expectations (all outcome-only):**

- The evergreen scan executed against all repo-tracked markdown files reports zero violations
- The five existing `<!-- evergreen-exempt -->` inline markers remain intact
- No new violations are introduced by the removal of the carve-out groups
- The jargon scan is unaffected
- The existing evergreen-lint job in CI reports zero violations after carve-out removal

## Why this is non-discriminating

`research/summary.md § Q7, Q16` confirms: "All 5 violations outside carve-outs already
carry `<!-- evergreen-exempt -->` markers; with carve-outs disabled but inline markers
active they would still pass."

Therefore, every listed test expectation passes equally whether or not the path-shaped
`case` branches are deleted:

| Scenario | Zero violations? | Markers intact? | CI passes? |
|----------|-----------------|-----------------|------------|
| Branches deleted (intended) | ✅ | ✅ | ✅ |
| Branches NOT deleted (silent failure) | ✅ | ✅ | ✅ |

The empty-RED condition is also broken: the test writer dispatched to establish RED
cannot write a test that currently fails (RED) and will pass after the deletion, because
no candidate assertion distinguishes the two scenarios.

## Traceability gap

`design.md` DKR5 commits: "Remove all 5 path-shaped exemption groups from
`_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats`." The Phase 1
acceptance block criterion 4 ("scan runs with all carve-outs removed and reports zero
violations") likewise does not detect non-deletion. No plan-authored criterion would
expose a silent failure of the G5 deliverable.

Note: `design.md`'s Test Strategy for G5 says "No new test code." That directive
applies to adding entirely new BATS assertions; it does not preclude adding a structural
code-pattern expectation that verifies the deletion. The round-1 version contained
exactly such an expectation without violating the "no new test code" spirit (it was a
declarative structural assertion on the source file, not a new test suite). Round 2
removed it, creating the gap.

## Suggested resolution

Re-add a structural test expectation that is GREEN only when the branches are absent:

> `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains no
> path-shaped `case` pattern branches after the modification (structural code-pattern
> assertion; grep of the function body confirms zero `case` branch lines matching a
> path-pattern shape)

This expectation is RED against the current state (branches present) and GREEN only
after the G5 deletion, restoring the TDD RED/GREEN gate.
