---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-20.md:27,43-45,55-56
  - .worktrees/v0.7.2-release/task-20/scripts/dispatch-agent.sh:423-424,698-700
  - .worktrees/v0.7.2-release/task-20/scripts/dispatch-companion.sh:486-515
---
The required third-party launch/await chain is not implemented end-to-end. In batched mode, `dispatch-agent.sh` records third-party entries as pending without launching anything (`emit_dispatch_manifest_entry "" "pending"`), so manifest `await_cmd` is built with an empty job id. Then `dispatch-companion.sh await <job-id>` immediately fails with "not wired in this build" (exit 13) instead of capturing raw output to `<round-dir>/.dispatch/<tag>.raw`. This misses a core Task-20 requirement (functional background dispatch + raw capture + splitter materialization path).
