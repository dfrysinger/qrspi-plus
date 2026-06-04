finding_id: F01
severity: medium
change_type: correctness
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:159-167]
message: |
  Safe-default evidence expectation is only weakly asserted. The test checks only
  ^EVIDENCE=. (non-empty), while the task expectation requires evidence that explicitly
  names safe-default behavior. A regression like EVIDENCE=foo would still pass even though
  required semantic content (e.g. "safe default" / "QRSPI_INTERACTION_MODE absent") is missing.
