---
finding_id: R18-F04
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L162, docs/qrspi/2026-05-17-v07-release/research/summary.md:L89-L110]
artifact: design
round: 18
reviewer: quality-claude
---

Design line 162 justifies the N=2 carve-out threshold with this phrase: "based on a design-time synthesis using Q6/Q7's documented task-file template structure (typical task spec ~150-200 lines; combined two-task plan + specs estimated at <600 lines)."

The Q6/Q7 research summary (lines 89–110 of the companion research summary) documents the task-file template FIELDS — the frontmatter keys (lines 451–475 of `skills/plan/SKILL.md`) and the required body sections (lines 477–487). Neither Q6/Q7 nor the research summary provides an observed or estimated line count for a typical task spec. The "~150-200 lines" figure is a design-time inference — not a finding sourced from Q6/Q7.

Presenting the estimate as "based on Q6/Q7's documented task-file template structure" overstates the research backing. Q6/Q7 gives the template shape; the line-count estimate is a design judgment call. A reader who goes to Q6/Q7 to verify the 150-200-line claim will not find it there.

Fix: rephrase the parenthetical to distinguish the research-backed fact from the design inference. For example: "based on the task-file template structure documented in Q6/Q7 (frontmatter ~25 lines, body section headings ~11 lines; design-time estimate: full task spec ~150-200 lines; combined two-task plan + specs estimated at <600 lines)."
