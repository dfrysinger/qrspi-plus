---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L782-L788, docs/qrspi/2026-05-17-v07-release/plan.md:L804-L811, docs/qrspi/2026-05-17-v07-release/plan.md:L827-L835, docs/qrspi/2026-05-17-v07-release/plan.md:L857-L863]
artifact: plan
round: 2
reviewer: spec-claude
---

Four task frontmatter blocks (T25, T26, T27, T28) carry bare-integer dependency values instead of the T-prefixed form required by the round-1 normalization fix. The round-1 Group A fix normalized `dependencies:` to T-prefix across T16, T17, T18, T19, T30, T38, T39, but missed the four Slice 5 tasks that were added or retained with the same defect.

Specific violations:
- T25 frontmatter: `dependencies: [24]` — should be `[T24]`
- T26 frontmatter: `dependencies: [24]` — should be `[T24]`
- T27 frontmatter: `dependencies: [24, 26]` — should be `[T24, T26]`
- T28 frontmatter: `dependencies: [24, 27]` — should be `[T24, T27]`

Note: the body-level `- **Dependencies:** T24` lines for T25 and T26, and `- **Dependencies:** T24, T26` / `- **Dependencies:** T24, T27` for T27 and T28, are already correctly T-prefixed. Only the YAML frontmatter `dependencies:` fields need correction.

The frontmatter fields are the machine-readable fields consumed by the QRSPI orchestrator for dependency ordering and dispatch sequencing. Bare-integer values are inconsistent with every other correctly normalized task in the plan and risk being parsed incorrectly by any tool that expects the T-prefix form.

Fix: apply the same Group A normalization to all four frontmatter blocks.
