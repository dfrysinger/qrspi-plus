---
finding_id: scope-codex-F01
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:977-1001
artifact: structure
round: 11
reviewer: scope-codex
---

`structure.md` embeds executable shell implementation body for `scripts/round-prepare.sh`, including `if` branches, variable assignments, command substitutions, `echo` diagnostics, exit codes, and a `printf` write. Structure owns script entry points, CLI argument shapes, exported interfaces, and data-flow boundaries; it defers function/script bodies and line-by-line logic to Plan/Implement. The approved per-file/verbatim-block expansion covers upstream prose payload movement, but this is implementation code rather than a structural interface contract.

(Persisted by orchestrator from Codex chat-only return — see stored memory `copilot CLI task tool`.)
