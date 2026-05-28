---
finding_id: R13-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L47]
artifact: design
round: 13
reviewer: quality-claude
---

The G1 routing-schema section declares three "initial legal predicate keys" for conditional routing entries: `citation_density_floor`, `input_volume_max`, and `task_type`. Only `citation_density_floor` is actually used in the G5 dispatcher tolerance matrix (for `qrspi-research-specialist`). `input_volume_max` and `task_type` are introduced as vocabulary that downstream Plan and Implement tasks must implement, but no concrete v0.7 dispatch site consumes them.

This is a YAGNI violation. Defining two predicate keys with no current consumer means Plan must specify behavior for them (what "input volume" is measured in, what values `task_type` may take, how they AND-compose with other predicates), Implement must implement that behavior, and reviewers must check conformance — all for predicates that nothing in v0.7 uses. If a future goal needs `input_volume_max` or `task_type` predicates, they can be added at that time alongside the concrete dispatch site that uses them.

Proposed resolution: Remove `input_volume_max` and `task_type` from the "initial legal predicate keys" list at G1 design line 47. Keep only `citation_density_floor`, which has a concrete consumer in G5. If the design intends to signal that additional predicates are possible, a note like "additional predicate keys may be added by future goals as dispatch sites require them" is sufficient without committing to specific unimplemented keys.
