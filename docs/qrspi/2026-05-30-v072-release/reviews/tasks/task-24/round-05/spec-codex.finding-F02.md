finding_id: F02
severity: medium
change_type: scope
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:528-540, docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:60]
message: |
  Test coverage: the grep regression for the Claude Code literal `## Auto Mode Active` checks only
  agents/ and explicitly excludes skills/; task-24.md:60 names both "consumer skill prose or agent
  bodies", so the skills/ half is not covered by an automated regression.
