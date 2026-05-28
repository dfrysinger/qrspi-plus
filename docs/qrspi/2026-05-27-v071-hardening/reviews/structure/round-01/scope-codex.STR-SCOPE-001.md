---
finding_id: STR-SCOPE-001
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
artifact: structure
round: 1
reviewer: scope-codex
status: applied
---

`agents/*.md (41 files)` is a wildcard, not a concrete per-file path list. Structure OWNS requires concrete repo-relative paths for every touched file (no placeholders/globs).

**Resolution:** added enumerated `### Slice 8 agent file enumeration` listing all 41 concrete `agents/qrspi-*.md` paths under the Slice 8 table.
