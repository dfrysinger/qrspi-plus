---
finding_id: R3-F05
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L13]
artifact: questions
round: 3
reviewer: quality-claude
---

Q7's second clause pre-asserts G3's planned mechanism. The question asks "what frontmatter/section contracts must any mechanical split preserve?" — the modal "must any mechanical split preserve" presupposes that a mechanical split is what's being designed, which is the exact deliverable G3 describes (delegating the post-approval `tasks/task-NN.md` split to a sub-subagent). A researcher reading Q7 alone learns that a mechanical task-file split is in the plan and that the goal of the research is to identify the contracts that split must preserve. Rephrase to ask only about the current contracts — for example, "What are the canonical task-file templates under `templates/` or referenced by `skills/plan/SKILL.md` for `tasks/task-NN.md`, and what frontmatter and section contracts do those templates currently document?" — leaving the question of whether anything downstream needs to preserve them to the design step.
