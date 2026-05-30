---
finding_id: R1-F04
severity: low
change_type: modified
artifact: plan
round: 1
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
---

# R1-F04: Task 4 and Task 9 both modify `agents/qrspi-parallelize-reviewer.md` but are declared fully parallelizable — co-modification not noted

## Location

`plan.md` → Overview dependency graph and Task 4 / Task 9 target files.

## Observation

The plan's dependency graph states:

> Tasks 1, 2, 3, 4, 5, 6, 9: no inter-task dependencies; may execute in any order or in parallel.

However, both Task 4 and Task 9 include `agents/qrspi-parallelize-reviewer.md` in their target files:

- **Task 4** modifies it to update Branch Map structural-rule assertions to require `### Wave N` sub-section grouping.
- **Task 9** modifies it (as one of the 41 `agents/qrspi-*.md` files) to delete the top-level `model:` YAML frontmatter key.

These edits are to different sections of the file — Task 4 modifies the prose/rules body, Task 9 modifies the YAML frontmatter — and are therefore likely non-conflicting in practice (different line ranges, separate git hunks). However:

1. The plan does not note this co-modification anywhere, which means Parallelize has no signal that these two parallel tasks touch the same file.
2. If the Parallelize reviewer assigns Tasks 4 and 9 to the same wave without this note, implementers working in parallel worktrees will produce a merge conflict requiring manual resolution, even though the edits are logically independent.
3. The omission leaves `goals.md`'s cross-cutting note unanswered: "G7b conflicts with anything else that edits agent frontmatter" — while this note targets frontmatter conflicts specifically, the co-modification of the same file still warrants a callout.

## Why it matters

The Parallelize step consumes the plan's dependency graph as its primary input. An undocumented co-modification on the same file is exactly the class of structural information Parallelize needs to assign tasks to disjoint worktree branches or to a safe sequential ordering. Leaving it implicit means the Parallelize reviewer must infer it from scanning every task's full target-file list rather than reading a dependency callout.

## Suggested resolution

Add a co-modification note to the plan's dependency graph section, such as:

> **Co-modification note:** Task 4 and Task 9 both touch `agents/qrspi-parallelize-reviewer.md` (Task 4: prose rule assertions; Task 9: YAML frontmatter `model:` deletion). The edits are line-disjoint and should not conflict, but Parallelize should assign them to separate worktree branches to ensure a clean merge path.

This is advisory rather than a hard dependency constraint — the plan need not mandate sequential execution, only make the co-modification explicit for Parallelize's wave-assignment decision.
