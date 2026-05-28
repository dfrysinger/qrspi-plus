---
finding_id: R6-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L553-L560]
artifact: design
round: 6
reviewer: scope-codex
---

The G12 recommendation crosses from design-level approach into an implementer-protocol command sequence. Design can choose the architectural decision — use a worktree-local ignore plus stage-before-scratch-write cleanup — but the six ordered shell commands (`git status --porcelain`, `git add -A`, `git commit -F`, `git rev-parse HEAD`) are procedural implementation detail. The Design DEFERS rule assigns line-by-line logic and implementation surfaces to Plan / Implement.

Fix by keeping the design-level contract and invariants here, then defer the exact command ordering and protocol text to Structure / Plan / Implement.
