---
finding_id: R3-F05
reviewer: sf-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F05 — Orphaned lock on process kill + misdiagnosed mkdir -p OUTPUT_DIR failure

**Convergent with sec-claude R3-F02 / sec-codex R3-F02.** sf-claude adds a related sub-case:

**Variant — mkdir -p OUTPUT_DIR failure misdiagnosed as lock contention:** if `mkdir -p "$OUTPUT_DIR"` fails (permissions), `mkdir "$_lock_dir"` (inside the non-existent dir) also fails — not because the lock is held, but because the parent doesn't exist. The spinlock loop misattributes this as 5 seconds of lock contention before emitting the lock-contention diagnostic — wasting 5 seconds + producing a misleading error.

**Fix:** explicitly check `mkdir -p "$OUTPUT_DIR"` exit before entering the spinlock; surface "OUTPUT_DIR creation failed" as a distinct diagnostic. Stale-lock detection (sec-claude R3-F02 fix) handles the SIGKILL path.
