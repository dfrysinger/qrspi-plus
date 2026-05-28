---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L23-L38]
artifact: goals
round: 2
reviewer: quality-claude
---

G1's `type` is `known-fix`, but the goal body contradicts that classification. The "What we know so far" bullets explicitly state "The schema shape is open" and enumerate multiple architecturally distinct alternatives Design must choose among: "a per-subagent default with per-task override fields, a per-run config block with a defaults map, or a layered combination." The Problem statement frames G1 as "design the *shape* of that policy layer" — i.e. the shape itself is the open question, not just the wording.

A `known-fix` goal communicates to Design that the deliverable is settled and only execution details need design judgment. G1 instead presents a genuinely open architectural decision space (which layers are required, what override precedence rules apply, how trusted-path carve-outs are vocabularized). That sits squarely in `exploratory` territory.

The mismatch matters because Design's depth-of-exploration heuristics are calibrated by `type`. If G1 is treated as `known-fix`, Design may under-explore the alternative schema shapes; the resulting design.md may pick the first reasonable shape rather than weighing the trade-offs the goal itself acknowledges are open.

Recommended fix: re-tag G1 as `type: exploratory`. The Cross-Cutting Notes already characterize the routing trio as a design surface with distinct jobs-to-be-done; making G1 exploratory aligns the per-goal tag with that framing.
