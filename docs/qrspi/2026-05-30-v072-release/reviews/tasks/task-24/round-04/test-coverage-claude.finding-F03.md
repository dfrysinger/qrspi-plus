finding_id: F03
severity: low
change_type: clarity
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:353-384, .worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:145-154]
message: |
  Missing no-file-write assertion for the Claude Code branch. The no-file-write property is verified
  for Copilot CLI (L357) and unknown host (L373) but not Claude Code. Symmetry omission; low risk in
  current impl (branch is three printf + exit 0) but becomes relevant if the branch is extended. Fix:
  add a "[T24] Claude Code branch creates no files at all" @test using $BATS_TEST_TMPDIR + find n_files -eq 0.
