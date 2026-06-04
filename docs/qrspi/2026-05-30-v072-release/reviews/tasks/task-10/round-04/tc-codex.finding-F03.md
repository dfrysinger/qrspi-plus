---
finding_id: R4-F03
reviewer_tag: tc-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:42
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:54
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2088
---

# tc-codex R4 F03: AC5 over-constrains schema — convergent with gt-codex F01

AC5 requires `representative_score:` and explicitly fails if bare `score:` appears. Spec L42/L54 says "each score" — over-constraint risks rejecting a spec-conformant template under Reading A.

CONVERGENT with gt-codex R4 F01 (same trace-break observation). Disposition: covered by PI-V072-T10-005 (spec disambiguation in v0.7.3). The R3 disposition chose Reading B; this finding reasserts Reading A is also defensible.
