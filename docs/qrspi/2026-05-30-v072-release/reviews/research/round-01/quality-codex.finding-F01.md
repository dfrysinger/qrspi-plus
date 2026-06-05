---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/research/summary.md
artifact: research
round: 1
reviewer: quality-codex
---

`research/summary.md` is not a verbatim collation of only per-question `## Summary` blocks: it adds a synthesized `## Cross-References` section (summary.md:422-436) that is not part of the per-question summary blocks shown in companion files (e.g., q01-codebase.md:9-23 and q23-codebase.md:9-30 end their summaries before `## Full findings` with no cross-question synthesis section). This violates the "summary.md is a verbatim extraction" requirement.
