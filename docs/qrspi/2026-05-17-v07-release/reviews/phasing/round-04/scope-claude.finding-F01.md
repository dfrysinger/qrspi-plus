---
finding_id: R4-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L33]
artifact: phasing
round: 4
reviewer: scope-claude
---

The Slice 6 description names the implementation dispatch mechanism directly: "delegates per-task spec authoring to sub-subagents dispatched in parallel from the main chat, with an N≤2 carve-out that keeps the split inline." The DEFERS rule flags "subagent dispatch verbs" and "implementation prose" as boundary-drift signals — naming the mechanism ("sub-subagents"), the dispatch site ("from the main chat"), and the inline-vs-parallel split logic crosses from phasing vocabulary (end-to-end demonstrable unit) into Implement-layer territory.

The same slice's replan gate criteria (L91–L93) correctly uses behavioral/observable language ("dispatches per-task spec authoring in parallel and produces N separate per-task spec artifacts") — the gate criteria surface is fine. The drift is isolated to the `## Slices` body for Slice 6.

Proposed fix: restate the Slice 6 description in behavioral terms consistent with the gate criteria that follow it. For example: "End-to-end Plan post-approval split: an approved Plan with N≥3 tasks produces N separate per-task spec artifacts authored in parallel, with a carve-out for N≤2 plans. The split touches the plan skill layer (post-approval orchestration and N-threshold carve-out), the artifact layer (the overview/per-task split shape after approval), and the sub-authoring layer (per-task spec authoring contract). It is a vertical slice because the cost-optimization motive only materializes when orchestration, authoring contract, and resulting artifact shape land together. Demonstrable end-to-end on a single approved Plan: parallel authoring completes, per-task spec artifacts exist, and the overview artifact records phase-start state." This removes the dispatch-site ("main chat") and mechanism-name ("sub-subagents") while preserving all phasing content.
