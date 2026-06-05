---
finding_id: F01
severity: medium
change_type: correctness
artifact: structure
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/structure.md
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/design.md
---

`structure.md` now exposes `scripts/round-prepare.sh <round-NN> <output-dir> [--task-branch <name>] [--implementer-commit <SHA>] [--verify]`, but only documents the partial-use error for `--task-branch` without `--implementer-commit`. Design CD-1 says the per-task pair is required together and rejected on partial use; with the current structure interface, the reverse partial case (`--implementer-commit` without `--task-branch`) is not defined.

Add an explicit rejection/exit contract for that case, or group the two options together in the signature so the interface remains concrete and complete. Per design.md L62, the canonical form is `[--task-branch <worktree-path> --implementer-commit <40-char-SHA>]` — paired in a single bracket group.

(Persisted by orchestrator from Codex chat-only return.)
