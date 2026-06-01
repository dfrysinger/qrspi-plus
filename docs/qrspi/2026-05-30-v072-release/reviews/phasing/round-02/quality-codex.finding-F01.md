---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: phasing
round: 2
reviewer: quality-codex
---

## `phasing.md` claims no future-phase content but `design.md` carries explicit v0.7.3+ planning

**Summary.** `phasing.md` asserts there is no future-phase content (`## Future-phase content` says none; `deferred_to_future: 0`), but the
current-phase pruned artifact set contains explicit future-release content in
`design.md` (multiple "Open Questions for v0.7.3+" sections and future
follow-up planning). That violates the four-artifact pruning quality rule
("no future content leaked into current-phase artifacts") for a single-phase
release.

**Required fix.** Remove/relocate future-release planning text from
current-phase artifacts into the appropriate `future-*.md` channel (or strip
it entirely if truly out of scope), so current artifacts contain only Phase 1
content consistent with phasing's "none deferred" claim.
