finding_id: F03
severity: low
change_type: clarity
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:272-294, .worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:151-153]
message: |
  Output-shape/enum coverage omits the Claude branch. Shape tests cover Copilot/unknown/override
  but not Claude-specific stdout lines. Claude-only formatting regressions (non-KEY=VALUE,
  bad DETECTION_TYPE) could slip through. Recommend Claude-branch variants of KEY=VALUE and
  DETECTION_TYPE-enum assertions.
