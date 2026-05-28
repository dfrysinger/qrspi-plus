---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md
artifact: plan
round: 1
reviewer: goal-traceability-claude
---

The `dependencies:` frontmatter field uses inconsistent notation across task specs. Several tasks use bare integers while others use T-prefixed identifiers. The full set of affected tasks:

- T16: `dependencies: [14]` — should be `[T14]`
- T17: `dependencies: [13, 15]` — should be `[T13, T15]`
- T18: `dependencies: [13, 15]` — should be `[T13, T15]`
- T19: `dependencies: [13, 14]` — should be `[T13, T14]`
- T38: `dependencies: [15]` — should be `[T15]`
- T39: `dependencies: [13, 38]` — should be `[T13, T38]`

By contrast, T03 (`[T01, T02]`), T07 (`[T03, T05, T06]`), T11 (`[T08, T10]`), T32 (`[T13, T31]`), T36 (`[T13, T33, T34, T35]`), and T42 (`[T13, T41]`) all use T-prefix notation correctly.

The inconsistency has two consequences for goal traceability: (1) automated dependency-graph tools that scan the frontmatter for T-prefix identifiers will silently miss the bare-integer edges, potentially miscomputing the critical path through the plan; (2) a reviewer checking whether a goal's covering tasks are correctly sequenced must mentally disambiguate notation rather than relying on a uniform schema.

The schema defined in the plan's overview section uses T-prefix notation throughout (e.g., "T01 -> T02 -> T03" in the dependency chain description), so the bare-integer form in frontmatter is inconsistent with the plan's own stated convention.

Resolution: normalize all `dependencies:` values to T-prefix notation. The fix is mechanical and applies to the six frontmatter blocks identified above.
