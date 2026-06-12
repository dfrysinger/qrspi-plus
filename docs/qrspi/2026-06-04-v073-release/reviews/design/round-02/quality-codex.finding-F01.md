---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L319-L385]
artifact: design
round: 2
reviewer: quality-codex
---

The orchestration-boundary report path is internally inconsistent: the design defines `<artifact-dir>/reviews/<phase>/orchestration-boundary.md` and phase names like `integrate`, but acceptance later requires `reviews/integration/orchestration-boundary.md`. This mismatch makes the contract ambiguous for implementers/tests and can cause checks to read/write different locations. Pick one canonical phase/path naming and update all references to match.

