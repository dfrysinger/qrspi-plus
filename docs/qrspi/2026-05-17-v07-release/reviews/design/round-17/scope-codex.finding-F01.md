---
finding_id: R17-F01
severity: medium
change_type: scope
referenced_files: ["/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L618-L620", "skills/design/owns-defers.md:L1-L21"]
artifact: design
round: 17
reviewer: scope-codex
---

The G12 commit-hygiene section crosses from design-level invariants into Plan/Implement-owned procedure by spelling out the concrete git command sequence: `(1) git add -A`, `(2) Write the scratch commit-message file`, `(3) git commit -F .qrspi-commit-msg.txt` plus cleanup. `skills/design/owns-defers.md` says Design owns architecture-level decisions and test strategy, while line-by-line procedural logic is deferred to Plan / Implement. The surrounding prose even says the literal git command sequence belongs in `skills/implementer-protocol/SKILL.md`, but the design still embeds that sequence.

Resolve by keeping the three architectural invariants in Design (staging before scratch-file creation, cleanup after commit, worktree-local exclude) and moving the exact ordered command sequence to Plan/Implement-owned artifacts.
