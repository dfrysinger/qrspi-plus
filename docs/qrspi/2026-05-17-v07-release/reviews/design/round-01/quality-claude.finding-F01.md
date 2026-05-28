---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L941-L950]
artifact: design
round: 1
reviewer: quality-claude
---

Decision 10 in the "Key architectural decisions" section enumerates the new task-spec fields that are "additive and have safe defaults" and lists exactly four: `reference_gate: true`, `reference_artifact: <path>`, `ui: true`, and `lift_source: <path>`. But the design also introduces at least one more task-spec field that is not in this enumeration: `id_hygiene_exempt: [<paths>]`, defined in G7's "Path-shaped carve-outs" (L313) as a per-task frontmatter field used to opt specific paths out of the ID-hygiene self-check.

Decision 10 reads as the authoritative roll-up of new task-spec surface (it is referenced indirectly elsewhere when discussing v0.6 backward compatibility, e.g., "A task spec that does not set these fields should behave exactly like a v0.6 task"). Downstream skills (Plan, Parallelize, Implement) will treat this list as the contract for what frontmatter to recognize. If `id_hygiene_exempt` is left off, either (a) implementers will not implement the carve-out the G7 design promised, or (b) the carve-out will be implemented inconsistently with the explicit defaults treatment Decision 10 commits the other four fields to.

The fix is to either (1) add `id_hygiene_exempt: [<paths>]` to Decision 10's enumeration with its safe default (absent → no carve-outs beyond the path-shaped defaults), or (2) reframe Decision 10 to scope it explicitly to "the four reference/UI fields" rather than as a roll-up, and add a parallel sentence in G7 confirming additive/safe-default semantics for `id_hygiene_exempt`.

This is a correctness defect rather than scope: the field is already proposed inside G7; Decision 10 is meant to summarize the cross-goal task-spec additions and currently does so incompletely.
