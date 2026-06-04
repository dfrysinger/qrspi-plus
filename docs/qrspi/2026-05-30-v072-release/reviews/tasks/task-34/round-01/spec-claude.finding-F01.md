---
finding_id: R1-F01
reviewer_tag: spec-claude
round: 1
task: 34
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F01 — Quick-fix N=1 path behavioral tests cover only 2 of 5 audit cases

Quick-fix path tests cover only: header emission, matching-hash safe-skip. Missing: quick-fix-labeled behavioral tests for mismatch halt, missing-header halt, malformed-header halt, and absent-file re-run (case 1).

Task spec DoD requires all five quick-fix audit rules to be behaviorally validated.

(Overlaps with codex F02.)
