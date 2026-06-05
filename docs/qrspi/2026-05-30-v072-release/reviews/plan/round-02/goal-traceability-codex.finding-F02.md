---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 22, 23, 42, 43, 44 — G24 re-scope"
referenced_files:
  - plan.md
  - design.md
---

# F02 — G24 re-scope mismatch: design locks to F05 only, plan still schedules F01/F02/F03/F04 work

## Defect

Design re-scopes G24 to F05 only (design.md ~2045–2066): F01/F03/F04 marked moot and F02 deferred/absorbed.

Plan still includes G24 tasks beyond F05:
- Task 22 → F02
- Task 23 → F04
- Task 42 → F01
- Task 43 → F03
- Task 44 → F05 (this one matches design)

## Impact

Plan schedules four tasks (T22, T23, T42, T43) whose underlying F-scopes design has retired. Duplicates work or re-introduces retired scope.

## Recommended fix

Either (a) verify whether T22/T23/T42/T43 carry distinct value beyond G24's F-scope (and if so, re-label their goal-ID to whatever absorbing goal owns them), OR (b) remove the standalone tasks. Design's re-scope is the source of truth.

## Verification note

This is a high-severity finding because four tasks are potentially mis-scoped, which would inflate Phase 1 by ~8% (4/44 tasks) on work design retired.
