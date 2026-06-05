finding_id: F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:60, .worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:430-456]
message: |
  Traceability gap: task criterion requires the grep regression to enforce that
  host-specific literals are allowed ONLY in scripts/detect-interaction-mode.sh and
  this test fixture, but the tests only assert ABSENCE of the literals in skills/ and
  agents/. There is no allowlist/exclusivity assertion proving the literals are confined
  to exactly those two files (a new file elsewhere containing a literal would not be caught).
