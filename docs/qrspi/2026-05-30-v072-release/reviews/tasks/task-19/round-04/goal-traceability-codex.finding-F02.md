---
finding_id: F02
reviewer_tag: goal-traceability-codex
round: 4
severity: medium
change_type: test_coverage
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:42
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:52
  - tests/unit/test-second-reviewer-available.bats:287-311
  - tests/unit/test-second-reviewer-available.bats:448-497
  - scripts/second-reviewer-available.sh:55-58
status: open
---

# goal-traceability-codex — round 4 — F02 (medium / test_coverage)

The unavailable-path DoD requires each unavailable class to emit exactly one
`[second-reviewer-unavailable]` line naming host+vendor. Coverage is partial:
the unknown-vendor override asserts non-zero + tag only (no one-line check, no
host field), and the empty-default-vendor guard checks one-line + tag but not
host/vendor naming. This leaves the full diagnostic contract under-specified in
tests.

Converges with test-coverage-codex F01/F02. Disposition: test-only additive
(extend assertions to pin one-line + host=/vendor= naming across the
unknown-vendor and empty-default paths); no production change.
