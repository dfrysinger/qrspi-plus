---
finding_id: R3-F02
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: code-quality-claude
round: 3
task: 34
---

Mixed test-name prefixes `[T32-split]` vs `[split]` within the same file.

The file contains two coexisting tag namespaces with no comment explaining the split:
- `[T32-split]` — 26 pre-existing tests (lines 54-361) from T31/T32 work
- `[split]` — all new G5 tests (lines 367-1250) added by T34

R2 correctly stripped `[T34-G5]` → `[split]` on tests it added in R1, but the result leaves two competing prefixes with no signal to future contributors which to use. The two groups test different surfaces (T32 dispatch-contract aspects vs T34 block-hash/idempotency), so there IS latent semantic value, but neither the file header (`# T32 — G3`) nor any inline comment documents that distinction.

**Fix (lower risk):** add a short setup-block comment documenting the two tag groups and their scope, so future contributors know which to use.

**Fix (cleaner long-term):** unify all tags to `[split]` and drop the task-origin prefix from the old tests (touches 26 names).
