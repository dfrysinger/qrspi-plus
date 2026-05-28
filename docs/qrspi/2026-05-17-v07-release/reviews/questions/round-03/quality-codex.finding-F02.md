---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L17, docs/qrspi/2026-05-17-v07-release/questions.md:L7-L36]
artifact: questions
round: 3
reviewer: quality-codex
---

The set is missing a load-bearing research area implied by the goals: there is no question about how resumed runs currently load `config.md`, backfill newly added fields, warn on one-time migrations, or otherwise preserve compatibility for older run state. That gap matters because the goals make this a hard constraint for any new config surface (`goals.md:L17`), and G1/G2 both plausibly introduce configuration fields or defaults. As written, the questions investigate routing schemas, dispatch mechanisms, and external framework patterns, but they do not ask for the current repo's runtime-default/backfill contract, so Design would be forced to guess about a required compatibility behavior. Fix: add a codebase question that explicitly traces the existing `config.md` parsing/defaulting/backfill path for resumed runs and documents the repo's current warning/migration pattern.
