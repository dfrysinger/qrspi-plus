---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-await-round.bats
reviewer_tag: spec-codex
---

await-round output-bound test does not cover prompt-body leakage fixture required by spec.

Spec (tasks/task-12.md:57): audit combined stdout/stderr with both captured reviewer payload AND prompt-body fixtures.

Observed (tests/unit/test-await-round.bats:103-132): payload leakage check exists (SECRET-PAYLOAD-XYZZY), but no prompt-body fixture/assertion.

Impact: test-coverage gap on stated acceptance expectation.
