---
finding_id: F03
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
---

# Missing Area — G4 and G5 Have No Corresponding Questions

## Goals Not Covered

- **G4** — Canonical cumulative diff helper: how the `round-NN.diff` convention currently works, what the merge-base computation looks like, where the orchestrator currently inlines the `git merge-base` instruction, and what the v0.7.1 T2 incident looked like (wrong base causing a re-run).
- **G5** — Idempotent post-approval plan split: how the Plan skill currently splits the approved `plan.md` into per-task files, what the behavior is when per-task files already exist, and how session compaction currently affects mid-split state.

## Problem

Neither goal has a research question aimed at characterizing the current state. G4 requires understanding the merge-base computation ritual in `skills/implement/SKILL.md` (where exactly the prose describes the cumulative diff), whether a helper script already exists with a `--verify` flag, and how the per-round diff emission is currently wired. G5 requires understanding what `skills/plan/SKILL.md` says about the post-approval split step, how the sub-subagent architecture from issue #172 is currently described, and whether any idempotency language exists today.

Without research questions, Design will enter the G4 and G5 phases without baseline characterization of the existing code and documentation. The risk is particularly acute for G4: the goals note that "the fix consolidates the merge-base computation into one verified place," implying the research must locate all current ad-hoc sites in SKILL prose.

## Suggested Additions

**G4 question** (`[codebase]`):
> "How does `skills/implement/SKILL.md` currently instruct the orchestrator to compute the cumulative diff base for per-round `round-NN.diff` files? Does the skill inline a `git merge-base` command, reference a helper script, or use another mechanism? Is `scripts/round-diff.sh` or any equivalent script already present in the repository, and if so, what are its current arguments and behavior?"

**G5 question** (`[codebase]`):
> "How does `skills/plan/SKILL.md` describe the post-approval step that splits `plan.md` into per-task `tasks/task-NN.md` files? Does the skill describe this as a sub-subagent action (per issue #172), a direct orchestrator write, or another mechanism? What does the skill say — if anything — about the case where the target per-task files already exist, and how is session compaction handled?"
