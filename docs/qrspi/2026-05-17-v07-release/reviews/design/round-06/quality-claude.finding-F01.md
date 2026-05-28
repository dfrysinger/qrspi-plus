---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L501-L511, docs/qrspi/2026-05-17-v07-release/research/summary.md:L229-L231]
artifact: design
round: 6
reviewer: quality-claude
---

G11's framing of the current UI task-spec surface contradicts the research summary it is supposed to be grounded in.

Design.md line 501 states: "Current task-spec affordances: `task_type` has two values (`code` for TDD, `lightweight` for prose/prompt/doc). No UI-specific tag exists. The optional `ux` step in the pipeline addresses UI at the phase level (between Phasing and Structure), but by the time Plan emits tasks the UI-ness is no longer tagged."

However, `research/summary.md` Q15/Q16/Q30 states: "Current Plan task-spec template surfaces `wireframe_refs` and `ui_producing` only; it does not include a task-spec field for intentional visual deviations from the cited reference source." It also states that `agents/qrspi-visual-fidelity-reviewer.md` already exists and that Plan template carries `visual_fidelity_check.wireframe_refs` (with a `ui_producing` boolean) per Q6/Q7 (lines 100).

Two consequences for downstream implementers:

1. The design's proposed `ui: true` task-spec field (line 507) overlaps with the existing `visual_fidelity_check.ui_producing` boolean. The design does not reconcile the two. An implementer reading this design could either (a) add `ui: true` as a duplicate signal alongside `ui_producing`, (b) replace `ui_producing` with `ui:`, or (c) leave both and add coupling rules — three different outcomes from the same prose.

2. Line 511 says "Study the existing Keeplii `qrspi-visual-fidelity-reviewer.md` before authoring the v0.7 reviewer agent." This implies the v0.7 reviewer is new, but a `qrspi-visual-fidelity-reviewer.md` already exists in qrspi-plus' own `agents/` directory per Q15/Q16/Q30. An implementer could create a duplicate agent file instead of refining the existing one.

Suggested resolution: in G11's "What research found" subsection, acknowledge the existing `visual_fidelity_check.wireframe_refs` / `ui_producing` task-spec block AND the existing `agents/qrspi-visual-fidelity-reviewer.md` agent. Then state explicitly whether the new `ui: true` field replaces, supersedes, or coexists with `visual_fidelity_check.ui_producing`, and whether the v0.7 reviewer work refines the existing agent or creates a new one. Phasing/Plan can sequence the work, but the directional decision is a Design responsibility.
