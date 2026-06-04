---
finding_id: R1-F02
severity: medium
change_type: test-coverage
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-20.md:55-56
  - .worktrees/v0.7.2-release/task-20/tests/unit/test-dispatch-sites.bats:313-321
  - .worktrees/v0.7.2-release/task-20/scripts/dispatch-companion.sh:486-515
---
Task-20 test expectations require fixture coverage that `dispatch-companion.sh await <job-id>` is payload-silent and writes raw output under `.dispatch/<tag>.raw`. Current added tests only assert the `await` subcommand is recognized (not 127 / no "unrecognised subcommand"), and do not assert raw-file capture behavior. This allowed the non-functional await implementation to pass.
