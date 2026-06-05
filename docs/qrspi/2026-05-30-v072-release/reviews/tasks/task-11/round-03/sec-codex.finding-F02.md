---
finding_id: R3-F02
reviewer: sec-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F02 — Lock poisoning / manifest-write DoS via precreated lock directory

**File:** scripts/run-codex-review.sh lines 216-223

```bash
local _lock_dir="${manifest}.lock"
while ! mkdir "$_lock_dir" 2>/dev/null; do
  ...
  if (( _lock_attempt >= 100 )); then
    ... exit 1
  fi
```

Lock path is fixed and unauthenticated. If it already exists at start, the writer spins ~5s and exits 1. No ownership check, no staleness recovery.

**Attack scenario:** attacker pre-creates `$OUTPUT_DIR/.dispatch-manifest.json.lock` in a shared workspace. Every subsequent manifest append spins for 5 seconds and fails hard, blocking the dispatch flow and preventing audit-trail recording.

**Impact:** availability loss + audit-trail tampering (provenance recording prevented).

**Fix sketch:** record the lock holder's PID inside the lock dir at creation time. On spin retry, check if the recorded PID is still alive; if not, treat the lock as stale and break it. Bound staleness with a `mtime` check (e.g., > 60s without progress = stale). Same idiom as `/var/run/*.pid` recovery.
