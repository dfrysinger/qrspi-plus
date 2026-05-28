---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L522-L535, docs/qrspi/2026-05-17-v07-release/design.md:L546-L551]
artifact: design
round: 1
reviewer: quality-codex
---

The G12 recommendation says to preserve `git commit -F <path>` while also reordering the protocol to remove `.qrspi-commit-msg.txt` before staging. That order is internally inconsistent: if the scratch file is removed before the staging/commit step, `git commit -F .qrspi-commit-msg.txt` has no file to read. The test strategy repeats the contradiction by describing both a normal write-message/stage/commit/cleanup cycle and a resilience test where the scratch file is removed before staging.

Fix by making the commit order executable. For example: stage tracked work first, then write `.qrspi-commit-msg.txt`, run `git commit -F .qrspi-commit-msg.txt`, then remove the scratch file; keep the `.git/info/exclude` entry as the protection against accidental later staging. Alternatively choose a scratch path outside the worktree. The design must state one coherent sequence that both preserves file-based commit messages and prevents the scratch file from entering `git add -A`.
