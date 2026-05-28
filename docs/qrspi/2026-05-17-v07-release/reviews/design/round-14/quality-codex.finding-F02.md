---
finding_id: R14-F02
severity: high
change_type: intent
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L767-L773, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/goals.md:L271-L285]
artifact: design
round: 14
reviewer: quality-codex
---

The design unilaterally defers G16 instead of designing it, even though the approved goals artifact includes G16 as an in-scope `known-fix` with a concrete problem statement and expected bounded artifact-contract update. That is not just a trade-off inside the goal; it removes an approved release deliverable. Because `design.md` is supposed to cover all approved goals' problem statements, this deferral changes release intent and should be surfaced explicitly for user resolution rather than silently treated as a normal design choice.
