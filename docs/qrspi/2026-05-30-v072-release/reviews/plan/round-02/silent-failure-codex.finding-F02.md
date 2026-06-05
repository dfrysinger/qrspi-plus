---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 19 — G27 second-reviewer probe"
referenced_files:
  - plan.md
---

# F02 — Probe-failure path still defaults to `second_reviewer: false`

## Defect

T19 spec says Goals/using-qrspi migration sets `second_reviewer: false` on probe failure.

## Impact

This recreates the original silent opt-out class: second-reviewer capability failure can be converted into config defaulting rather than a caller-visible hard failure or explicit operator decision. The whole point of G27 is to surface this state to the operator.

## Recommended fix

On probe failure, halt and prompt the user with the two explicit options ("skip second reviewer" vs "abort"); do not silently default. The default `false` on failure IS the silent failure pattern this goal exists to eliminate.

## Counter-argument to consider

If the run is fully autonomous (no human in the loop), `false` may be the safest default. The fix may need to distinguish interactive vs autonomous modes rather than blanket-halt.
