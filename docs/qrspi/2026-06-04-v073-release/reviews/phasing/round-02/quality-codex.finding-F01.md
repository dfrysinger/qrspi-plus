---
artifact: phasing
reviewer: quality-codex
change_type: correctness
location: docs/qrspi/2026-06-04-v073-release/phasing.md:19
---

## Finding: Replan-gate criterion points to non-existent `## Acceptance` blocks

> All nine goal Acceptance criteria pass (per each goal's `## Acceptance` block in `design.md`).

design.md does not use `## Acceptance` headings; goal acceptance is `**Acceptance.**` bold inline (verified: design.md:23, 51, 124, 157, 184, 234, 262, 377, 409, 449, 489, 556).

Fix: "per each goal's `**Acceptance.**` subsection in `design.md`."
