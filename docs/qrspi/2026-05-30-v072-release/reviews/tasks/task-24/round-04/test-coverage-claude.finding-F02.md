finding_id: F02
severity: low
change_type: clarity
referenced_files: [.worktrees/v0.7.2-release/task-24/tests/unit/test-detect-interaction-mode.bats:462, .worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:151-154, docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:61]
message: |
  Missing output-shape KEY=VALUE loop test for the Claude Code branch. Shape loops exist for
  Copilot CLI (L462), unknown host (L475), and override (L272), but not Claude Code. The Claude Code
  INSTRUCTION line is long, contains single quotes/prose; if production emitted a multi-line
  INSTRUCTION the substring grep tests (L117-126) would still pass while a shape loop would catch it.
  task-24.md line 61 requires "every stdout line is a KEY=VALUE pair". Fix: add a shape-loop @test
  for the Claude Code branch.
