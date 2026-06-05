---
finding_id: R4-F01
reviewer: sf-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — Dispatcher failure exit code masked by manifest-write failure on the new "failed" path

**Regression introduced by R4 fix (Group E + Group D).**

On the non-zero dispatcher path (around line 947-951):
```bash
_dispatch_exit=$?
emit_dispatch_manifest_entry "" "failed"   # ← calls _append_manifest_entry which uses hard exit 1
exit "$_dispatch_exit"
```

`emit_dispatch_manifest_entry` (lines 351-376) calls `_append_manifest_entry` (lines 252-339). `_append_manifest_entry` uses hard `exit 1` on internal errors (jq failure, lock contention 5s timeout, mv failure — all the new fail-loud guards added in R4).

**Failure mode:** the actual transport dispatcher exits, say, with code 137 (SIGKILL'd by OOM) or 124 (timeout). We capture `_dispatch_exit=137`. We try to record the failure in the manifest. If the manifest write itself fails (disk full, NFS hiccup, stale lock that the 30s probe doesn't recover), `_append_manifest_entry` exits 1 — and the script exits 1 to its caller. The 137/124 is gone. Operators / automation see "manifest script failed" instead of "transport timed out."

This is an inappropriate error transformation. The original dispatcher exit class is the load-bearing signal; manifest write being unable to record it is a secondary concern that should be logged but not mask the primary failure.

**Fix sketch:**
```bash
emit_dispatch_manifest_entry "" "failed" || {
  echo "warning: failed-status manifest entry write failed (manifest may be incomplete); preserving dispatcher exit code" >&2
}
exit "$_dispatch_exit"
```

OR use `set +e` around the call so internal exits don't preempt:
```bash
( emit_dispatch_manifest_entry "" "failed" ) || true
exit "$_dispatch_exit"
```

The subshell isolates the `exit 1` from `_append_manifest_entry`. Either approach restores the dispatcher exit code as primary signal.
