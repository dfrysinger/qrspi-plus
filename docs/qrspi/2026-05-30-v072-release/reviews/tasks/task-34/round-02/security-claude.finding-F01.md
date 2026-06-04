---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files:
  - skills/plan/post-approval-split-contract.md
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: security-claude
---

Contract imposes no task-ID sanitization before path construction. `tasks/task-NN.md` is built from task IDs parsed out of `### Task N` blocks in plan.md. No format constraint (positive integer) or sanitization is required before `test -e` / write / diagnostic.

Attack: plan.md author inserts `### Task ../../../home/user/.ssh/authorized_keys: setup` → orchestrator parses ID = `../../../home/user/.ssh/authorized_keys` → constructs `tasks/task-../../../home/user/.ssh/authorized_keys.md` (resolves outside tasks/) → Case 1 absent → sub-subagent writes task spec body to authorized_keys, overwriting SSH access.

Fix: contract MUST validate every parsed task ID matches `^[0-9]+$` (positive integer) and reject non-conforming IDs with a named diagnostic before pre-fan-out. Add test: plan.md with `### Task ../evil:` triggers named parse-error halt before any filesystem op.
