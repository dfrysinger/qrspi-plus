---
finding_id: R01-F02
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/parallelization.md:L383
artifact: parallelize
round: 1
reviewer: scope-claude
---

The `## Operational Notes` **Stage commit hygiene** bullet prescribes Implement's runtime worktree-creation timing and references Integrate's runtime merge/dedup behavior:

> "Stage commits are scratch infrastructure **created by Implement immediately before the dependent Wave's worktrees are forked**. **Integrate handles dedup/cleanup at phase end** per `integrate/SKILL.md` § Merge Strategy."

Per the Parallelize DEFERS rule: *"Concrete commit hashes, branch creation, worktree creation … owned by Implement at runtime."* Specifying that Implement creates stage commits "immediately before the dependent Wave's worktrees are forked" is a runtime-timing prescription that belongs to Implement's execution procedure, not to Parallelize's planning output. Similarly, characterizing what Integrate does at phase end (dedup/cleanup) is Integrate-owned operational territory.

Parallelize legitimately owns the Stage Commits table (which stage branch to create, from which parents, to unblock which Wave) — that table already carries this information. The hygiene note adds runtime procedure on top of the plan, which overshoots the boundary.

The fix is to remove or trim this Operational Notes bullet. If a cross-reference is needed, it should be a plain pointer ("Stage commits are resolved by Implement and Integrate at runtime per their respective skill contracts") without prescribing Implement's timing or Integrate's cleanup procedure.
