---
finding_id: R4-F01
reviewer_tag: security-codex
round: 4
artifact: plan.md
severity: high
change_type: correctness
referenced_files: plan.md (lines 1170-1188, 1196-1216)
---

Task 20 plans to persist prompt/raw payloads under `<round-dir>/.dispatch/` and only remove them on normal `await-round.sh` completion, but the task spec has no requirement to add an interrupted-run safeguard (for example, a committed ignore rule) for those files. That creates a fail-open leak path: if a run halts before cleanup, sensitive dispatch prompt/raw artifacts remain in the working tree and can be accidentally committed or exfiltrated through normal repo workflows.

At Plan altitude this is a missing security acceptance criterion, not implementation detail: the task should require a durable safeguard for leftover `.dispatch/` artifacts in addition to best-effort runtime cleanup.
