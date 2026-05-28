---
finding_id: R15-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L154, docs/qrspi/2026-05-17-v07-release/research/summary.md:L43-L73]
artifact: design
round: 15
reviewer: quality-claude
---

G3's rationale for widening the small-plan carve-out threshold from N=1 to N=2 tasks cites "Q3 token budgets" as the basis: "a plan with exactly 2 tasks still fits in main chat context comfortably (combined LOC + task spec < 600 lines based on Q3 token budgets)."

Q3 (`research/summary.md` lines 43–73) covers the call shape, error handling, and stdout/stderr contract of `scripts/run-codex-review.sh` and `scripts/codex-companion-bg.sh`. It contains no token budget analysis, LOC estimates for task specs, or context-window sizing information. The citation is inaccurate — Q3 does not support the 600-line threshold claim.

The correct citation is likely Q6/Q7 (lines 92–111 of the research summary), which covers plan structure, the task-file template, and task-file format details including the canonical `tasks/task-NN.md` body section contract. That section would be the appropriate basis for estimating combined LOC + task spec size.

The fix is to change "based on Q3 token budgets" to "based on Q6/Q7 task-file template size" (or to remove the citation if the 600-line figure is an editorial estimate rather than a research-derived number). The threshold itself (N=2) is reasonable; only the supporting citation is wrong.
