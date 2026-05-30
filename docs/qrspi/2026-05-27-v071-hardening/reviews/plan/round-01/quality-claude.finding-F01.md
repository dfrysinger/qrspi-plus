---
finding_id: R1-F01
severity: medium
change_type: modified
artifact: plan
round: 1
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
---

# R1-F01: Task 5 adds new test code in direct contradiction of design.md's G5 test strategy

## Location

`plan.md` → Task 5, description and Dispatch order lines.

## Observation

`design.md` Test Strategy section states explicitly for G5:

> **G5 (TBD/TODO cleanup):** No new test code -- the existing evergreen-markdown unit test is the test. Coverage after fix: scan runs against the entire repo with zero carve-outs and zero violations.

Task 5 in the plan contradicts this directly:

> The test-writer writes a structural assertion verifying that `_is_path_exempt()` contains no path-shaped `case` branches (RED when branches are present, GREEN after deletion). Dispatch order: test-writer first, implementer second (RED-verification gate between).

The plan dispatches a test-writer for G5 and describes a new structural assertion that must be written before the implementer acts. This is new test code — exactly what the design says to avoid for this slice.

## Why it matters

The design decision reflects a deliberate choice: G5 is a deletion-only task where the regression guarantee is the existing scan's full-repo coverage after the carve-outs are removed. Adding a structural assertion that `_is_path_exempt()` contains no path-shaped branches:

1. Commits to a specific internal structure of the helper function (brittle if the function is later refactored to use a different mechanism)
2. Deviates from the approved design without an acknowledged departure reason
3. Sends the test-writer on an unnecessary pass, adding coordination cost with no coverage gain the design considered necessary

The plan must either remove the new assertion / test-writer dispatch and rely on the existing scan (matching design) or document an explicit departure from DKR5's test strategy with a justification.

## Suggested resolution

**Option A (match design):** Remove the test-writer dispatch step from Task 5. Task 5 becomes implementer-only: delete the six `case` patterns from `_is_path_exempt()`, then verify CI passes with zero violations. No new test code authored.

**Option B (override design with justification):** Retain the new assertion but add a `design_departure_reason` note in Task 5 explaining why the structural guard is worth the coupling cost and why the design's rationale for "no new test code" does not apply here.
