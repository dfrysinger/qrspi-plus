finding_id: F02
severity: medium
change_type: correctness
referenced_files: [.worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:131-145, .worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:60]
message: |
  No test covers discriminator precedence when both host signals are present. Script
  precedence is explicit (COPILOT_CLI branch before CLAUDE_PROJECT_DIR) but tests always
  unset one while setting the other. If branch order regresses, behavior under mixed-host
  env state is untested. Recommend a test with both COPILOT_CLI=1 and CLAUDE_PROJECT_DIR set
  (no override) asserting the intended winner (copilot-cli, llm-context).
