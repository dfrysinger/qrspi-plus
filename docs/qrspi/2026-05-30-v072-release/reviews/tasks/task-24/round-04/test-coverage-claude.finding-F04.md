finding_id: F04
severity: low
change_type: correctness
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats, .worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:131-154]
message: |
  No native-detection precedence test for simultaneous COPILOT_CLI=1 + CLAUDE_PROJECT_DIR set with no
  override. Every branch test unsets the non-target discriminator. Production relies on if-elif order
  (COPILOT_CLI before CLAUDE_PROJECT_DIR). If a future refactor swapped ordering or used a compound
  condition, the gap allows the regression to pass undetected. Fix: add a precedence @test with both
  discriminators set, no override, asserting PLATFORM=copilot-cli wins. (Convergent with test-coverage-codex F02.)
