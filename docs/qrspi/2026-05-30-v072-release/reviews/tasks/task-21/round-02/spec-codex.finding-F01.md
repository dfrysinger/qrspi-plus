---
reviewer: spec-codex
round: 2
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-agent.sh
  - tests/unit/test-dispatch-agent.bats
---

# F01 — Incomplete G16 hardening: batch-mode `--artifact` and `--agents` bypass the guard

Spec (task-21.md L19,24-25,39-43) requires "every prompt-ingested file path is canonicalized under $REPO_ROOT before its content can enter a sanctioned LLM channel."

Batch-mode paths in `scripts/dispatch-agent.sh` are still read without `assert_path_under_repo_root`:
- `--artifact` → `BATCH_ARTIFACT_ABS`, cat'd into prompt at L566-574, L680-684
- `--agents` agent path → `_agent_file`, read via `strip_frontmatter_batch` at L613-623, L675

G16 tests at L1453-1601 cover only `--subject-code`/`--artifact-body`/`--companion`/`--diff-file`. No batch-mode regression.

**Fix:**
1. Apply `assert_path_under_repo_root` after existence-check for `BATCH_ARTIFACT_ABS` and for each `_agent_file` from `--agents`.
2. Add bats tests for both: outside-repo path → reject + diagnostic + no prompt emission + no raw read.

**Adjudication: ACT.** Real spec gap; spec-claude missed it (R2 spec gate is mixed: spec-claude CLEAN, spec-codex this finding).
