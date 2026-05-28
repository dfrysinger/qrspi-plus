---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L28-L39, docs/qrspi/2026-05-17-v07-release/design.md:L227-L236]
artifact: design
round: 1
reviewer: quality-codex
---

G5 requires G1's routing schema to support conditional matrix predicates, but G1's schema definition only names role-to-provider mappings, per-task overrides, per-run defaults, provider config, and trusted-path carve-outs. Without a condition representation in G1, Plan cannot express G5's accepted matrix entries such as "cheap-model eligible with citation-density floor" or "conditional by task type/input volume"; those would collapse into ad hoc dispatch logic, which is exactly what G1 is meant to prevent.

Fix by adding conditional routing to the G1 schema contract: define where predicates live, what initial predicate keys are legal, how they interact with per-task/per-run overrides and trusted-path carve-outs, and add a G1 schema/precedence test for conditional resolution.
