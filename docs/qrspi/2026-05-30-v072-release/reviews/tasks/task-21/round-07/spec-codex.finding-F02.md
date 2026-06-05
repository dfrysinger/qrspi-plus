---
finding_id: F02
severity: LOW
change_type: advisory
referenced_files:
  - tasks/task-21.md:13
  - scripts/lib/path-guard.sh:1-3
reviewer_tag: spec-codex
round: 7
---

Target-files advisory: task-21 target list does not include scripts/lib/path-guard.sh, but it was modified. This is small and related, so likely acceptable auxiliary change; recommend either retroactively updating task target files to include this shared guard module or reverting non-essential edits there.
