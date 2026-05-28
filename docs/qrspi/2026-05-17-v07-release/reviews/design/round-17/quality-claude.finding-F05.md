---
finding_id: R17-F05
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L154, docs/qrspi/2026-05-17-v07-release/research/summary.md:L92-L111]
artifact: design
round: 17
reviewer: quality-claude
---

The G3 small-plan carve-out threshold justification overstates what Q6/Q7 research found, attributing a design-derived calculation to the research as if it were a research finding.

Design.md line 154 states: "Threshold widened from goals.md's N=1 to N=2 because a plan with exactly 2 tasks still fits in main chat context comfortably (combined LOC + task spec < 600 lines based on Q6/Q7 task-file template size)."

The research summary Q6/Q7 (research/summary.md lines 92-111) documents the task-file template structure: the split task-file template occupies lines 449-487 of `skills/plan/SKILL.md` (39 lines) and the in-plan task-spec template occupies lines 168-218 (51 lines). Q6/Q7 describes the template structure and the inline embedding location. It does NOT state or calculate that "combined LOC + task spec < 600 lines" for a 2-task plan or that 2 tasks fit comfortably in main chat context.

The "< 600 lines" calculation is the design's own synthesis — the design author multiplied the template sizes by 2 and added context overhead. That synthesis may well be correct, but attributing it to Q6/Q7 is inaccurate. A downstream agent or Plan author checking Q6/Q7 against this claim would not find the "< 600 lines" figure there.

Fix: change the attribution to make clear this is a design-time estimate derived from the Q6/Q7 template sizes, not a Q6/Q7 finding. For example: "Threshold widened from goals.md's N=1 to N=2 because a plan with exactly 2 tasks still fits in main chat context comfortably; estimated from Q6/Q7 template sizes (39-51 lines per task spec template × 2 tasks plus task spec body = well under 600 lines of context)."
