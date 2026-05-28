---
finding_id: R1-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L533-L534, docs/qrspi/2026-05-17-v07-release/plan.md:L550-L556, docs/qrspi/2026-05-17-v07-release/plan.md:L578-L582, docs/qrspi/2026-05-17-v07-release/plan.md:L601-L607, docs/qrspi/2026-05-17-v07-release/plan.md:L879-L884, docs/qrspi/2026-05-17-v07-release/plan.md:L1099-L1103, docs/qrspi/2026-05-17-v07-release/plan.md:L1123-L1128]
artifact: plan
round: 1
reviewer: quality-claude
---

Multiple task frontmatter blocks list dependency IDs without the canonical `T` prefix used elsewhere in the plan. The inconsistency appears in at least seven tasks:

- T16: `dependencies: [14]` — should be `[T14]`
- T17: `dependencies: [13, 15]` — should be `[T13, T15]`
- T18: `dependencies: [13, 15]` — should be `[T13, T15]`
- T19: `dependencies: [13, 14]` — should be `[T13, T14]`
- T30: `dependencies: [13, 24, 25, 26, 27, 28, 29]` — should be `[T13, T24, T25, T26, T27, T28, T29]`
- T38: `dependencies: [15]` — should be `[T15]`
- T39: `dependencies: [13, 38]` — should be `[T13, T38]`

By contrast, T32 (`dependencies: [T13, T31]`), T42 (`depends on: T13, T41`), T22 (`dependencies: [T13]`), and T23 (`dependencies: [T13, T20, T21]`) all use the `T` prefix correctly. The inconsistency will confuse any tooling or downstream agent that parses the frontmatter dependency list using the canonical `T<NN>` form and relies on consistent token shapes. The overview's task-listing summary (lines 27-77) uses the `T` prefix consistently throughout; the inconsistency is confined to the YAML frontmatter blocks.

Resolution: normalize all dependency entries in YAML frontmatter to the `T<NN>` form, matching the canonical convention used in the task-listing summary and in the correctly-authored tasks.
