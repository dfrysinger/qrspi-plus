---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Overview paragraph vs Dependency Graph / Task List by Slice
referenced_files: [plan.md]
---

# F02 — "Only cross-slice prerequisite is G4→G9" is contradicted by later dependencies

The Overview claims G4→G9 is "the only cross-slice prerequisite" and that "otherwise each slice's tasks chain only within-slice" (plan.md:11). But the same document later defines another cross-slice chain: T09 (Slice 1.2) + T11 (Slice 1.2) + T13 (Slice 1.3) feeding T20 (Slice 1.4) (plan.md:50, 56, 62, 66, 72, 106–112).

This is an internal planning contradiction that can mislead sequencing/parallelization decisions for round ordering and merge planning.

**Suggested fix:** update the Overview claim to acknowledge the T09/T11/T13→T20 cross-slice prerequisite (or re-slice/re-home T11 if the intent was to keep cross-slice prerequisites singular).
