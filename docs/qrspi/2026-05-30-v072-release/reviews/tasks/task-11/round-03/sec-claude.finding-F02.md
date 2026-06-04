---
finding_id: R3-F02
reviewer: sec-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F02 — Stale mkdir lock on unexpected process termination — permanent manifest DoS

**Location:** `_append_manifest_entry` lines 218-235 (mkdir-as-mutex block)

```bash
while ! mkdir "$_lock_dir" 2>/dev/null; do ... done
...
mv "$tmp" "$manifest"
rmdir "$_lock_dir"   # never reached if process dies here
```

No `trap` handler installed. If SIGKILL/SIGTERM hits between mkdir and rmdir, the lock directory persists forever. Every subsequent dispatch for the same round-dir spins 100 attempts (5s) and aborts.

**Convergent with sec-codex R3-F02** (same root cause). sec-claude adds the trap-handler fix sketch:

```bash
trap 'rmdir "$_lock_dir" 2>/dev/null; exit 1' INT TERM EXIT
...
rmdir "$_lock_dir"
trap - INT TERM EXIT
```

SIGKILL cannot be trapped; combine with mtime-based staleness check (auto-break locks older than N seconds) for full coverage.

**Attack vector:** any process with write access to OUTPUT_DIR can pre-create `.dispatch-manifest.json.lock/` before dispatch runs — permanent DoS with a single mkdir.
