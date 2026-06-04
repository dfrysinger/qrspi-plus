---
finding_id: R2-F01-sec
reviewer_tag: security-claude
round: 2
severity: high
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats, agents/qrspi-plan-reviewer.md]
adjudication: accepted
---
**Claim:** G18 `none`-claim shell-metachar/dash-prefix validation (agent § Cross-task consumer surface detection step 2) is present and inlines the full forbidden-char list, but has ZERO test pins. G15's analogous grep-proof hardening has 5 dedicated security pins (bats L344-382). A future prose-simplification could silently strip the G18 injection guard with no test failure — command-injection regression path (reviewer re-runs author-supplied `none` search command from repo root).

**Adjudication: ACCEPTED.** Security surface; purely additive test-only fix (mirror the 5 G15 security pins against H3 "Cross-task consumer surface detection"); not a refactor. Fix mirrors G15 L344-382 but MUST match actual G18 prose (e.g. "require `--` argument separator" not G15's "-- '" example literal; "reject patterns starting with `-`" not G15's "NOT start with").
