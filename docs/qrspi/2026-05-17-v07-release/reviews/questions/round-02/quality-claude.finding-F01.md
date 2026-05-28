---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L8]
artifact: questions
round: 2
reviewer: quality-claude
---

Q2's parenthetical enumeration leaks G1's candidate schema shapes.

The question reads: "...what schema shapes (per-role defaults, per-task overrides, layered precedence) are common in their published configs?" The parenthetical names exactly the schema candidates listed in goals.md G1 ("What we know so far"): "a per-subagent default with per-task override fields, a per-run config block with a defaults map, or a layered combination" plus the source-issue framing "per-subagent + per-task + per-run defaults." A researcher reading only this question would correctly infer the project is shopping for a per-role / per-task / layered routing schema — that is the design space G1 wants Design to weigh, not a precondition the researcher should be told.

Recommend dropping the parenthetical so the question reads as a general survey: "...what schema shapes are common in their published configs for routing dispatch decisions across components?" The researcher can then return whatever shapes actually appear in OSS configs rather than confirming the three the goal already named.
