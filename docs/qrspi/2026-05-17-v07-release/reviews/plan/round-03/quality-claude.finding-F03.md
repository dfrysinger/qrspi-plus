---
finding_id: R3-F03
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1281-L1289]
artifact: plan
round: 3
reviewer: quality-claude
---

T43's frontmatter carries `conditional: true` as a field (line 1288), but this field does not appear in the canonical task-spec frontmatter schema documented elsewhere in plan.md (the "Split task file format" template, the in-plan task-spec template, or the task ordering section). None of the other 42 tasks use this field. As a result, the Plan skill's post-approval split sub-subagent (T31) — which receives the canonical task-file template as input — has no documented guidance for what `conditional: true` means or how downstream tools (the Implement orchestrator, the status tracker) should interpret it. The T43 Description paragraph explains the conditional semantics in prose, but the frontmatter field is undocumented in the schema. The fix is to either (a) add a brief `conditional:` field definition to plan.md's task-spec template section noting that `conditional: true` marks a task as a NO-OP unless its gating spike report selects the triggering path, or (b) remove `conditional:` from the frontmatter and rely solely on the Description paragraph for the conditional semantics.
