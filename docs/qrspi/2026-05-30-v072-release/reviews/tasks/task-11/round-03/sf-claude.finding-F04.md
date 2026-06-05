---
finding_id: R3-F04
reviewer: sf-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F04 — Failed dispatch always recorded as status:"pending" (misleading audit) + empty job_id produces unactionable await_cmd

**File:** scripts/run-codex-review.sh lines 810-831

```bash
_dispatch_exit=0
_dispatch_stdout="$( set -o pipefail; compose_prompt | bash "$DISPATCHER" ... )" \
  || _dispatch_exit=$?
# ... JOB_ID strip loop ...
_job_id=""   # may remain empty if dispatcher failed
emit_dispatch_manifest_entry "$_job_id"   # always called, always writes status:"pending"
exit "$_dispatch_exit"
```

**(a) status:"pending" hardcoded on failure:** `emit_dispatch_manifest_entry` always sets `--arg status "pending"` regardless of `_dispatch_exit`. When the dispatcher failed, the manifest still records a pending entry that any downstream await-and-split tool will try to await — but the job never started. The exit code IS propagated to the caller, but the persisted manifest state is wrong forever.

**(b) Empty job_id → unactionable await_cmd (convergent with sf-codex R3-F02):** `_job_id=""` produces `await_cmd: "scripts/run-third-party-llm.sh await "` (trailing space, no id). Operator can't distinguish "dispatch failed" from "pre-T20 dispatcher didn't emit JOB_ID yet."

**Fix:** pass `_dispatch_exit` to emit_dispatch_manifest_entry and conditionally write status:"failed" when non-zero. Or gate emit_dispatch_manifest_entry on success and skip the manifest entry entirely on failure (after logging the diagnostic).
