---
finding_id: R14-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L153-L161]
artifact: design
round: 14
reviewer: quality-claude
---

The G3 small-plan carve-out sets the threshold at "2 tasks or fewer → split in main chat." The goals.md (G3, "What we know so far") says "Quick-fix or one-task plans are a candidate carve-out, since the overhead of sub-subagent dispatch may exceed the split cost." The design extended the threshold from one task to two tasks but provides no rationale for why the carve-out was expanded to include two-task plans.

This matters for an implementer reading the design: the carve-out boundary is a behavioral contract that Implement must enforce, and the reasoning behind "N=2" versus "N=1" is not stated. Without rationale, a future reader cannot tell whether N=2 was deliberate (e.g., because two parallel sub-subagents have non-trivial coordination cost for the orchestrator) or was an unexamined extension.

Proposed fix: add one sentence in the G3 trade-offs or recommendation section explaining why the threshold is two rather than one — for example, "Two tasks are included in the carve-out because the orchestration overhead of dispatching two parallel sub-subagents (await loop, file-count verification) is comparable to the cost of writing two task files in main chat."
