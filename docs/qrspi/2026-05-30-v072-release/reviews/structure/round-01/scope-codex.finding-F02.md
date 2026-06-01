---
finding_id: R1-F02
severity: medium
change_type: scope
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Structure OWNS "cross-cutting hook-point locations" (per v0.7.1 owns-defers.md), but
the artifact does not enumerate concrete hook placement sites across files (the
File Map gives per-file responsibilities and the Interfaces section gives signatures
only). Add a dedicated hook-point location map (file + exact section/location) for
cross-cutting insertions — for example, the four compaction-callout placement sites
per skill, the `!cat` include sites the G34/G35 shared snippets land at, the four
introducer-prose insertion points for scope-reviewer agents — locations only, never
the text (text content remains DEFERS).

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
