---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md]
artifact: phasing
round: 1
reviewer: scope-claude
---

The OWNS rule requires phasing.md to author a `roadmap.md` — described as "the canonical phase → slice → goal-ID mapping table" and "the source of truth for which goals belong to which phase via which slice; downstream skills (Structure, Plan, Replan) read from it." No roadmap.md section, content, or reference to its authoring appears anywhere in phasing.md. The `## Goal-ID Consistency` section acknowledges goal IDs but does not substitute for the structured mapping table that downstream skills consume.

This is a missing OWNS deliverable, not a style issue. Structure and Plan are defined to read from roadmap.md; without it being authored in the Phasing step, those downstream skills have no authoritative source to reference. The fix is to add a `## Roadmap` section (or equivalent) to phasing.md that maps each phase → each slice → the goal IDs it contains, in the tabular or structured form the OWNS rule describes.
