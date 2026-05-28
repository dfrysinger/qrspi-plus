---
finding_id: R1-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L146-L148]
artifact: parallelize
round: 1
reviewer: scope-claude
---

The `## Worktree-aware setup validation` section (lines 146–148) contains worktree-setup advisory content that the OWNS/DEFERS rule assigns to Implement at runtime, not to Parallelize.

The section makes positive implementation-setup assertions: it declares that no `.worktrees/**` path exclusions are needed in `.gitignore` or CI configuration, characterizes what per-task worktrees will contain ("shell scripts, markdown files, BATS test files, and JSON artifacts"), and identifies the `.git/info/exclude` append for `.qrspi-commit-msg.txt` as the sole per-worktree filesystem advisory for this release. The DEFERS rule states: "Concrete commit hashes, branch creation, worktree creation, baseline tests, runtime-injected `task-00` — owned by Implement at runtime; Parallelize records only symbolic bases."

Worktree-setup validation — deciding what worktrees need in `.gitignore`, CI, and `.git/info/exclude` — is a runtime-setup concern owned by Implement. Parallelize's job is Wave membership, file-overlap analysis, symbolic Branch Map, and Stage Commits; it does not author advisory content about what the Implement orchestrator should configure before worktree creation.

The fix is to remove the `## Worktree-aware setup validation` section entirely from `parallelization.md`. If this content belongs anywhere, it belongs in `skills/implement/SKILL.md` (the per-task execution protocol) or as a note in the task spec for task-39 (the task that authors the `.git/info/exclude` append).
