---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [phasing.md:L108-L112, future-design.md:L33-L57]
artifact: phasing
round: 4
reviewer: quality-codex
---

The pruning summary claims `future-design.md` contains only deferred design content for `G16 + FD-01..FD-04`, but `FD-01`, `FD-02`, and `FD-04` are corrections to current-phase v0.7 decisions (`G1`, `G17`, and `G3` respectively), not future-release design work. That means current-phase content has leaked into a `future-*` artifact, violating the pruning contract that future artifacts contain only deferred future-phase material. Fix either by moving those v0.7-correction entries back into the current-phase design/review loop or by explicitly narrowing `future-design.md` to genuinely deferred future-phase content only.
