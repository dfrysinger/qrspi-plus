---
finding_id: R3-F01
severity: low
change_type: style
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/parallelization.md:L119-L130
  - docs/qrspi/2026-05-17-v07-release/parallelization.md:L182
artifact: parallelize
round: 3
reviewer: quality-claude
---

The Branch Map's Base column for all 12 Wave 1 tasks uses `feature branch tip` (with spaces) rather than the canonical hyphenated form `feature-branch-tip` required by the symbolic-base vocabulary in the reviewer protocol. The same non-canonical form appears in the Mermaid subgraph label on line 182: `Wave 1 — feature branch tip`.

The affected rows are lines 119–130 (task-01 through task-41 Wave 1 entries) and the Mermaid subgraph label. Each of those 12 Branch Map rows and the graph label should read `feature-branch-tip`.

Proposed fix: replace every occurrence of `feature branch tip` with `feature-branch-tip` throughout the document (Branch Map base column and Mermaid subgraph label).
