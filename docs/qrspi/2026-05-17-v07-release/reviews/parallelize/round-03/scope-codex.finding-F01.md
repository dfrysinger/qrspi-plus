---
finding_id: R3-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L168-L170]
artifact: parallelize
round: 3
reviewer: scope-codex
---

The `## Worktree-aware setup validation` section still crosses the Parallelize boundary. The Parallelize OWNS rule covers dependency topology, file-overlap analysis, wave membership and bases, symbolic Branch Map / Stage Commits, Mermaid graph, and Execution Mode; it explicitly DEFERS concrete worktree creation and runtime setup concerns to Implement.

Lines 168-170 make runtime setup assertions about `.worktrees/**` exclusions, expected per-worktree contents, build artifact behavior, and the `.git/info/exclude` append for `.qrspi-commit-msg.txt`. Those are Implement/worktree setup decisions, not parallelization topology. The fix is to remove this section from `parallelization.md`; if the advisory is still needed, it belongs in the Implement protocol or the task-39 spec, not in the Parallelize artifact.
