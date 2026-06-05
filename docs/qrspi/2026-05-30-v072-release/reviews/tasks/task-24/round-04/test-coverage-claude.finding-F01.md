finding_id: F01
severity: medium
change_type: correctness
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:430-456, docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:60]
message: |
  No grep regression for the Claude Code auto-mode signal `## Auto Mode Active` in agents/.
  Four grep-regression tests guard Copilot-CLI literals (autopilot_mode, "Autopilot mode is
  currently active") against skills/ and agents/, but the Claude Code signal has ZERO regression
  tests. task-24.md line 60 literally requires rejecting host-specific auto-mode literals in
  "consumer skill prose or agent bodies" — the agents/ half for the Claude Code signal is entirely
  unimplemented. An agents/ regression is unambiguously feasible (no agent .md should reference the
  signal). Fix: add a test running `grep -rl '## Auto Mode Active' "$REPO_ROOT/agents"` asserting
  status -eq 1. (A skills/ regression would need to whitelist the two known legacy files
  goals/SKILL.md:12 and design/SKILL.md:12 which already cite the signal as documented precedent.)
