---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Multiple tasks (T22, T26, T27, T28, T30, T31, T33, T36, T37, T38)"
referenced_files:
  - plan.md
---

# F01 — Non-deterministic "R1-R7 / content-semantic review" expectations

## Defect

Several tasks use test expectations like "apply R1-R7 + cross-cutting principles" / "content-semantic review" without concrete pass/fail signals.

## Impact

These are not reliably falsifiable for acceptance-test generation. Two reviewers could disagree while both claim R1-R7 was satisfied. Same defect class as the round-01 fixes addressed in other tasks.

## Recommended fix

For each "R1-R7 / content-semantic" test expectation, replace with specific observable assertions: required strings present, forbidden strings absent, structural assertions (heading present, section ordering), and the specific R-rule each assertion maps to.

## Counter-argument to consider

The R1-R7 framework IS the testable contract — if R1-R7 are precisely-defined elsewhere (a reviewer spec doc), then "apply R1-R7" is a deterministic shorthand. The fix is to either pin the R-rule definitions or expand them inline; both options have trade-offs (DRY vs locality).
