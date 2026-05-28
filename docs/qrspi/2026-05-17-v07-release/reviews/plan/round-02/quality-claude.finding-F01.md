---
finding_id: R2-F01
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L787
  - docs/qrspi/2026-05-17-v07-release/plan.md:L810
  - docs/qrspi/2026-05-17-v07-release/plan.md:L833
  - docs/qrspi/2026-05-17-v07-release/plan.md:L862
artifact: plan
round: 2
reviewer: quality-claude
---

Four task frontmatter blocks carry bare integer values in their `dependencies:` lists instead of T-prefixed task IDs. The round-1 fix (goal-traceability-claude.R1-F02 / quality-claude.R1-F02) normalized the `dependencies:` frontmatter to T-prefix for T16, T17, T18, T19, T30, T38, and T39, but the same defect class was missed for T25, T26, T27, and T28.

Current values (incorrect):
- T25 frontmatter (plan.md:L787): `dependencies: [24]`
- T26 frontmatter (plan.md:L810): `dependencies: [24]`
- T27 frontmatter (plan.md:L833): `dependencies: [24, 26]`
- T28 frontmatter (plan.md:L862): `dependencies: [24, 27]`

Required values (matching the body "Dependencies:" lines and the overview task list):
- T25 frontmatter: `dependencies: [T24]`
- T26 frontmatter: `dependencies: [T24]`
- T27 frontmatter: `dependencies: [T24, T26]`
- T28 frontmatter: `dependencies: [T24, T27]`

The body "Dependencies:" text for each task already uses the T-prefix (e.g., T25 body reads "**Dependencies:** T24") and the overview task list (lines 56–59) uses T-prefix consistently. Only the YAML frontmatter blocks are missing the prefix. Fix: add the `T` prefix to each integer in the four frontmatter `dependencies:` lists.
