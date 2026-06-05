---
finding_id: R4-SF-F01
reviewer: silent-failure-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
at_cap: true
escalate: true
---

# F01 — SIGTERM/SIGINT trap releases lock without exiting — concurrent writes race after signal

**Introduced by R4 Group D (EXIT/INT/TERM trap added to `_append_manifest_entry`).**

## Location

`scripts/run-codex-review.sh` lines 266–270 (lock acquisition) and line 270 (trap registration):

```bash
if mkdir "$_lock_dir" 2>/dev/null; then
  _manifest_lock_dir="$_lock_dir"
  trap 'rmdir "$_manifest_lock_dir" 2>/dev/null || true' EXIT INT TERM
  break
fi
```

## Failure mode

When SIGINT or SIGTERM arrives **while the lock is held** (i.e., after `mkdir "$_lock_dir"` succeeds but before `trap - EXIT INT TERM` disarms the trap on the normal return path), bash executes the trap handler — which releases the lock via `rmdir` — and then **resumes execution from where the signal interrupted the function**.

After the trap handler returns, `_append_manifest_entry` continues: it runs `jq ... > "$tmp"` and `mv "$tmp" "$manifest"`. But the lock has already been released. A concurrent `_append_manifest_entry` invocation (e.g., a second reviewer tag being dispatched in the same wave) can now acquire the lock between the signal and the resumed `mv`, and both processes land their `mv` calls to the same destination.

Since `mv` is not atomic across two simultaneous writers — the last `mv` wins — one writer's append is silently overwritten. The manifest loses an entry with no error message and exit code 0 from the surviving invocation.

```
Process A (holds lock, receives SIGTERM):
  1. trap fires → rmdir lock  ← LOCK RELEASED
  2. Process B acquires lock
  3. Process B reads manifest, jq-appends its entry, mv to manifest
  4. Process B releases lock
  5. Process A resumes: mv "$tmpA" "$manifest"  ← CLOBBERS B's entry
  6. Process A exits normally
  Result: B's manifest entry is silently lost.
```

For EXIT the trap is correct (exit is already in flight). The problem is specific to INT and TERM: the trap handler does not call `exit`, so the function body continues after the handler returns and the lock is gone.

## Why this is silent

- No error is printed; `_append_manifest_entry` completes with the normal clean-up path (`trap - EXIT INT TERM`, `rmdir`, `eval "$_saved_opts"`).
- Both invocations see exit 0.
- The manifest contains one entry instead of two; the missing entry is not detected until a downstream consumer (e.g., `verifier-fan-in`) notices a reviewer's round is unrecorded.

## Precondition

Requires concurrent invocations against the same `OUTPUT_DIR` **and** SIGINT/SIGTERM arriving in the narrow window between lock acquisition and lock release. AC4 tests concurrent writes but does not inject signals. This window is narrow in practice but is opened by any operator Ctrl-C or orchestration teardown that sends SIGTERM to the dispatch subshells.

## Fix

Add `exit` calls to the INT and TERM trap bodies so the function does not resume after the signal:

```bash
_manifest_lock_dir="$_lock_dir"
trap 'rmdir "$_manifest_lock_dir" 2>/dev/null || true' EXIT
trap 'rmdir "$_manifest_lock_dir" 2>/dev/null || true; exit 130' INT
trap 'rmdir "$_manifest_lock_dir" 2>/dev/null || true; exit 143' TERM
```

Standard signal exit codes (130 = 128+SIGINT, 143 = 128+SIGTERM) are used so callers can detect the kill signal from the exit code. The lock is still cleaned up before exit, preserving the stale-lock-free invariant the stale probe relies on.
