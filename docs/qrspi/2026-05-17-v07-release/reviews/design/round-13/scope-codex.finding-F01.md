---
finding_id: R13-F01
severity: medium
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L594-L603]
artifact: design
round: 13
reviewer: scope-codex
---

The G12 recommendation crosses Design's boundary by spelling out the implementer commit procedure as an ordered command-level sequence, including `git status --porcelain`, `git add -A`, writing `.qrspi-commit-msg.txt`, `git commit -F`, cleanup, and `git rev-parse HEAD`. The Design OWNS/DEFERS rule allows architecture-level decisions and test strategy, but defers line-by-line procedural logic and concrete implementation procedure to Plan / Implement.

Fix: keep the design-level contract and rationale here, but move the exact six-step command sequence to the downstream Plan / Implement artifact. For example, Design can say the accepted approach requires staging before scratch-file creation, post-commit cleanup, and worktree-local exclusion, while leaving the literal command ordering to the implementation plan.
