finding_id: F02
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:61, .worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:509-522, .worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:117-126]
message: |
  Spec-to-test fidelity gap: criterion says output-shape tests must assert no placeholder
  values are present, but placeholder checking is only done for the COPILOT_CLI branch.
  Claude/override/unknown-host outputs are not checked for placeholder-only values, so the
  acceptance criterion is only partially covered.
