---
finding_id: R2-F01
severity: medium
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1151-L1155
  - agents/qrspi-finding-verifier.md#L72-L73
---

TC5's "line-range" fixture uses `refs="[README.md#L99999-L99999]"`, but verifier Cite Check documents line-range citations as `path:line` / `path:line-line`. This mismatch means the fixture does **not** exercise the intended line-range parsing/error path; regressions there can pass silently while the test still appears to validate line-range behavior.
