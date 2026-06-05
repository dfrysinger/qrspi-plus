---
finding_id: F01
severity: medium
change_type: security
referenced_files:
  - scripts/dispatch-agent.sh
---

Batch-mode --artifact and --output-dir path strings skip the new
reject_if_path_unsafe_for_emission guard. Single-mode is covered;
batch path (713-717) emits raw path strings into wrapper markers.
Same root cause as sf-claude F01.
