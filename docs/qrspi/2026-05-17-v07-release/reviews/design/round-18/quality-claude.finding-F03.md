---
finding_id: R18-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1162-L1164]
artifact: design
round: 18
reviewer: quality-claude
---

The cross-cutting test strategy section (line 1162–1164) covers two boundary cases for the G3 Plan post-approval split:

- "For a plan with three or more independent tasks, post-approval split runs sub-subagents in parallel..."
- "For a plan with one task, post-approval split runs in main chat..."

However, the G3 design decision widens the main-chat carve-out to N≤2 (line 162: "when `plan.md` has 2 tasks or fewer, do the split in main chat"). The cross-cutting test strategy does not include the N=2 boundary case. A reader scanning only the cross-cutting section would not know that two-task plans also stay in main chat.

The G3 section itself does include a "Boundary test (N=2)" (line 176), so the gap is in the cross-cutting summary only — it is incomplete relative to the design decision.

Fix: add a third bullet to the Plan post-approval split paragraph in the cross-cutting test strategy: "For a plan with exactly two tasks, post-approval split runs in main chat (within the small-plan carve-out) and produces two `tasks/task-NN.md` files."
