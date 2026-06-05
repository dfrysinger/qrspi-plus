---
finding_id: quality-codex-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:2431-2462
  - docs/qrspi/2026-05-30-v072-release/design.md:2472-2493
  - docs/qrspi/2026-05-30-v072-release/design.md:2503-2533
  - docs/qrspi/2026-05-30-v072-release/structure.md:2271-2302
  - docs/qrspi/2026-05-30-v072-release/structure.md:2322-2364
  - docs/qrspi/2026-05-30-v072-release/structure.md:3331-3338
artifact: structure
round: 11
reviewer: quality-codex
---

The `## Section Contracts` table conflicts with the per-file verbatim full-body specifications for the G31 prompt-prose snippets and wrapper SKILLs. For example, the table requires `skills/_shared/prompt-prose-detection.md` to have `## Prompt-Prose Detection`, and wrapper SKILLs to have `## Overview`, `## Detection`, etc.; but the lifted design payloads have no such headings and instead define the exact file bodies (`# Prompt Prose Writer`, then two `!cat` lines, etc.). An implementer following both sections cannot satisfy both. Remove or revise the Section Contracts rows so they match the lifted full-file bodies.

(Persisted by orchestrator from Codex chat-only return.)
