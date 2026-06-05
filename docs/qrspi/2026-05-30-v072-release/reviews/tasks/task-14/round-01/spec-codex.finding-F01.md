---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---
title: G15 integration tests do not verify sweep detection/pause behavior or malformed dependent_tests outcomes
evidence:
  - Task DoD requires test coverage for (a) positive sweep detection + missing-field pause and (b) malformed variants
  - Added tests grep for wording in docs/agent text, not behavior against task fixtures
  - "positive detection" check is text match at lines 283-287
  - "malformed variants" check is regex on reviewer prompt text at lines 310-316
impact: Required acceptance criteria for G15 are unverified; regression risk remains for actual pause/finding behavior.
recommended_fix: Add behavior-level integration tests feeding sweep-shaped task specs through Plan review/pause path.
