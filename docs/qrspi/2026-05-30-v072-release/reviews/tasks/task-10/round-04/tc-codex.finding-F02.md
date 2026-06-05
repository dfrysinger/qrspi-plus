---
finding_id: R4-F02
reviewer_tag: tc-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:52
  - tests/unit/test-verified-file-shape.bats:152
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2007
---

# tc-codex R4 F02: No test for threshold-conditional defect_class requirement

Spec L52 requires: sub-threshold clarity/correctness MUST require `defect_class`, while above-threshold MAY carry it without changing keep/drop behavior. Current tests only pin generic presence/shape/fallback (unit) and acceptance only tests drop-behavior with low scores. No test exercises the **conditional requirement** by threshold/category.

Disposition: ACCEPT-WITH-ISSUES, file backlog PI-V072-T10-012 (~10 LOC bats test addition in v0.7.2.x or v0.7.3).
