---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F02 — Quick-fix N=1 parity coverage is incomplete

Spec requires quick-fix path to cover absent, match, mismatch, missing-header, malformed-header audit rules per task-34.md lines 45, 58.

Implemented tests (lines 778-821): only header emission and matching-hash safe-skip are covered.

Missing tests: quick-fix mismatch halt, missing-header halt, malformed-header halt, and absent-file re-run case.
