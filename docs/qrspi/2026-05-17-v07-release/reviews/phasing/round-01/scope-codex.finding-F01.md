---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L13-L33]
artifact: phasing
round: 1
reviewer: scope-codex
---

The `## Slices` section repeatedly crosses from phasing's owned vertical-slice boundaries into Structure/Implement territory by naming concrete file paths, script names, field names, transport branches, CI workflow paths, and implementation mechanics inside the slice definitions. Phasing owns the end-to-end delivery units and their phase grouping, but the OWNS/DEFERS rule defers file paths, module boundaries, interface contracts, hook syntax, and implementation prose to later artifacts. Fix by keeping each slice at the capability/layer boundary level and moving concrete file/script/field mechanics to Structure, Plan, or Implement-owned artifacts.
