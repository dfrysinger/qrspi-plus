---
artifact: design
reviewer_tag: scope-codex
finding_id: scope-codex-F02
change_type: scope
---

# G6 acceptance covers validation but not capture step

## Location

design.md G6 Acceptance bullets L410-415.

## Finding

R09 introduced a new capture step (resolve task tips before merge, write to runtime sidecar). Acceptance only checks validation helper. Design-owned acceptance shape is missing for the capture behavior.

## Expected fix

Add an acceptance bullet: a fixture proves task tips are resolved before merge, written to the runtime sidecar, consumed by validation, and NOT written back to parallelization.md (preserving symbolic-branch-map invariant). Acceptance shape only — test code is Plan's call.
