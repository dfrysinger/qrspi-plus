---
finding_id: F02
reviewer: silent-failure-codex
severity: medium
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:749-753, scripts/dispatch-agent.sh:756-758, scripts/dispatch-agent.sh:766]
disposition: DEFER-v0.7.3
---
**Per-agent launch failure converted to overall batch exit 0.** When dispatch-companion launch fails or returns no JOB_ID, manifest records the failure but loop continues and exits 0 — callers reading exit status see success. **DEFER** — out of T21 scope (T21 = path-filter exfil hardening). Valid concern for v0.7.3 batch-dispatch reliability hardening.
