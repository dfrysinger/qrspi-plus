finding_id: F01
severity: high
change_type: scope
referenced_files: [.worktrees/v0.7.2-release/task-24/scripts/detect-interaction-mode.sh:9, docs/qrspi/2026-05-30-v072-release/tasks/task-24.md:25]
message: |
  Completeness/Interpretation: task Scope/In says "implement the three documented detection
  protocols: shell-verdict, llm-context, user-override-only". The script emits only llm-context
  (lines 139,152) and user-override-only (113,162); there is no runtime branch emitting
  DETECTION_TYPE=shell-verdict. Codex flags this as an unimplemented protocol (HIGH).
