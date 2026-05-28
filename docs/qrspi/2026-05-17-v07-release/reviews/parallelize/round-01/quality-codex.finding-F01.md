---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L65-L69, docs/qrspi/2026-05-17-v07-release/parallelization.md:L107-L112, docs/qrspi/2026-05-17-v07-release/parallelization.md:L133-L136]
artifact: parallelize
round: 1
reviewer: quality-codex
---

The Branch Map bases the Wave 4 and Wave 5 `skills/implement/SKILL.md` tasks on `stage-after-W2`, even though the Execution Order says Wave 3 task-05 edits `skills/implement/SKILL.md`, Wave 4 task-11 must be isolated because it edits that same file, and Wave 5 task-27 edits it again. As written, task-11 would fork before task-05's Wave 3 edit, and task-27 would fork before both task-05 and task-11, creating stale-base branches with likely merge conflicts or lost prose.

Fix: add the required stage point after Wave 3 and use it as task-11's base, then add/use a Wave 4 stage (or otherwise explicitly compose task-11 into the stage used by Wave 5) so task-27 is based on the prior `skills/implement/SKILL.md` changes it must build on.
