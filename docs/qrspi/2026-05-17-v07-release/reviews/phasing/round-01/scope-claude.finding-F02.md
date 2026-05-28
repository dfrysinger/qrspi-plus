---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md]
artifact: phasing
round: 1
reviewer: scope-claude
---

The OWNS rule requires two related deliverables that are entirely absent from phasing.md:

1. **Current-phase pruning** — splitting goals.md, questions.md, research/summary.md, and design.md into current-phase content (kept in place) and deferred content moved to future-*.md files. Individual research/q*.md files are explicitly NOT split per the OWNS rule.

2. **Future-* artifact maintenance** — creating and updating future-goals.md, future-questions.md, future-research-summary.md, and future-design.md, which Replan consumes during between-phase transitions.

Neither deliverable is defined, scoped, or mentioned anywhere in phasing.md. Since v0.7 is a single-phase release (all goals in Phase 1), one might argue the split is trivial — but the OWNS rule applies unconditionally, and the future-* files are the boundary contract that Replan depends on. Even if all goals are in Phase 1 and the future-* files are empty, they still need to exist and be explicitly addressed.

The fix is to add a section (e.g. `## Artifact Pruning`) that explicitly states which goals/questions/research/design content is current-phase vs. deferred, and documents the state of the four future-* files (even if their conclusion is "all content is current-phase; future-* files are empty stubs").
