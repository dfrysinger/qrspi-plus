---
finding_id: R1-F03
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:533
  - docs/qrspi/2026-05-17-v07-release/plan.md:555
  - docs/qrspi/2026-05-17-v07-release/plan.md:606
artifact: plan
round: 1
reviewer: spec-claude
---

The `dependencies:` frontmatter field is inconsistently formatted across tasks. Some tasks use the `T`-prefix form (e.g., `dependencies: [T03, T05, T06]` at T07) while others use bare integers (e.g., `dependencies: [14]` at T16 line 533; `dependencies: [13, 15]` at T17 line 555; `dependencies: [13, 14]` at T19 line 606; `dependencies: [13, 38]` at T39; `dependencies: [T13, T38]` at the same task body). The inconsistency appears specifically in the frontmatter YAML blocks, not in the task-list overview (which consistently uses the `T`-prefix form).

Affected frontmatter blocks with bare integers:
- T16: `dependencies: [14]`
- T17: `dependencies: [13, 15]`
- T18: `dependencies: [13, 15]`
- T19: `dependencies: [13, 14]`
- T39: `dependencies: [13, 38]`

All other tasks use the `T`-prefix form in their frontmatter.

The plan's task-overview section (lines 28–78) consistently uses the `T`-prefix convention (`depends on: T13`, `depends on: T01, T02`). The bare-integer form in the frontmatter of five tasks is either a typo or a diverged convention, but it creates ambiguity for any tool or agent that parses the frontmatter `dependencies:` field programmatically — a bare `13` could be parsed as integer `13` rather than task-ID `T13`.

**Fix:** Normalize all `dependencies:` frontmatter values to the `T`-prefix form used by the majority of tasks and by the plan overview section. Replace `[14]` → `[T14]`, `[13, 15]` → `[T13, T15]`, etc., across T16, T17, T18, T19, and T39.
