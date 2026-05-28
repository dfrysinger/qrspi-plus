---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md]
artifact: phasing
round: 3
reviewer: scope-claude
---

The phasing.md artifact is entirely silent on two OWNS responsibilities: (a) current-phase pruning of the four synthesizing artifacts (goals.md, questions.md, research/summary.md, design.md), and (b) future-* artifact maintenance (future-goals.md, future-questions.md, future-research-summary.md, future-design.md).

The OWNS/DEFERS rule explicitly names both as Phasing's property: "Current-phase pruning of four synthesizing artifacts — split goals.md, questions.md, research/summary.md, and design.md into current-phase content (kept in place) and deferred content (moved to future-*.md)" and "Future-* artifact maintenance — future-goals.md, future-questions.md, future-research-summary.md, future-design.md are created and updated each Phasing run."

The dispatch note confirms the companion files exist on disk, so this is not a deliverable-missing finding about the companion artifacts themselves. The gap is that phasing.md contains no section, note, or reference documenting (i) what was pruned from each of the four synthesizing artifacts, (ii) the rationale for what landed in current-phase vs. deferred, or (iii) confirmation that the future-* artifacts were created/updated. Downstream skills (Structure, Plan, Replan) read from roadmap.md and the pruned artifacts; a reader of phasing.md has no way to audit the pruning boundary without consulting the companion files independently.

To resolve: add a section (e.g. `## Pruning Summary`) that records for each of the four synthesizing artifacts what content was kept in place vs. moved to the future-* file, and confirms the future-* artifacts were created or updated this run. The section need not be exhaustive — a brief table or per-artifact note is sufficient — but something must appear in phasing.md to make the pruning boundary auditable from the phasing artifact itself.
