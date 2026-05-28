---
finding_id: R9-F03
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L140-L156, docs/qrspi/2026-05-17-v07-release/design.md:L1081-L1085]
artifact: design
round: 9
reviewer: quality-claude
---

G3's small-plan carve-out threshold is 2 tasks, but the test strategy only exercises the 1-task case, leaving the 2-task boundary case unspecified.

G3 (line 140) sets the carve-out threshold as:

> **Small-plan carve-out:** when `plan.md` has 2 tasks or fewer, do the split in main chat.

G3's own test strategy (lines 152–153):

> - Multi-task test: a plan with three or more tasks dispatches sub-subagents in parallel and produces one `tasks/task-NN.md` per task.
> - Single-task test: a plan with one task does the split in main chat and still produces a `tasks/task-NN.md`.

And the cross-cutting test strategy (lines 1083–1084) repeats the same gap:

> - For a plan with three or more independent tasks, post-approval split runs sub-subagents in parallel and produces one `tasks/task-NN.md` per task.
> - For a plan with one task, post-approval split runs in main chat and still produces a `tasks/task-NN.md`.

The threshold is `<= 2`, but no test fixture pins the behavior at exactly 2 tasks. Plan and Implement implementers reading the design have two consistent threshold statements and a test set that exercises N=1 and N=3+ but not N=2 — the boundary case where the carve-out's value proposition is weakest (sub-subagent overhead vs. two-task split cost).

This is a low-severity correctness issue: the design is internally consistent on the threshold, but the test strategy under-specifies the boundary case that most operators would want to see pinned.

Suggested fix: add a boundary test to G3's test strategy and the cross-cutting summary: "Boundary test: a plan with exactly 2 tasks does the split in main chat (carve-out applies); a plan with exactly 3 tasks dispatches sub-subagents in parallel."
