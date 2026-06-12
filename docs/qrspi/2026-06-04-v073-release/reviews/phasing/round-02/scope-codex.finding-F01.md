---
artifact: phasing
reviewer: scope-codex
severity: medium
change_type: scope
---

## Finding: Intra-slice sequencing drifts into Plan/Parallelize-owned territory

`phasing.md` adds an "Intra-slice sequencing constraints" bullet under Phase 1 that specifies ordering/pairing constraints among goals and references Wave ordering:

> G9's skill-body trim must land after G1–G7...
> G6 and G7 are designed and implemented as a paired unit...
> Wave ordering for these constraints is owned by Plan...

Per Phasing DEFERS, ordered task lists/task sequencing are owned by Plan, and Wave decisions are owned by Parallelize. Phasing should limit itself to slices, phase grouping, and replan-gate criteria.

Remove this sequencing bullet from `phasing.md` or reduce it to phase/slice-level scope only, leaving ordering/wave decisions to Plan/Parallelize.
