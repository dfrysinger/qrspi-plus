---
finding_id: F01
reviewer: silent-failure-codex
model: gpt-5.3-codex
round: 7
task: 11
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh:930
---

# silent-failure-codex — task-11 round-07 — F01 (HIGH)

**FIX-M trap swallows INT/TERM — script continues after interruption.**

The new first-party tmpfile trap handles `INT`/`TERM` as cleanup-only:

```bash
trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM
```

This does NOT `exit` afterward. In bash, trapping INT/TERM without exiting causes execution to continue after the trap returns. The script may proceed to `printf 'DISPATCH_FILE=...'` and `emit_first_party_manifest_entry`, masking an aborted dispatch and potentially announcing a dispatch with no actual prompt file present (mv-failed-but-trap-already-cleaned-up).

## Comparison to FIX-H

`_append_manifest_entry` (lines 288-290) correctly uses **three separate trap lines** with explicit exits:

```bash
trap '... ; rmdir "$_manifest_lock_dir" ...' EXIT
trap '... ; rmdir "$_manifest_lock_dir" ...; exit 130' INT
trap '... ; rmdir "$_manifest_lock_dir" ...; exit 143' TERM
```

FIX-M was supposed to mirror FIX-H but collapsed three traps into one and dropped the `exit 130`/`exit 143` calls. This breaks the signal-cancellation contract that FIX-H upheld.

## Suggested fix

Split the combined trap into three separate traps mirroring FIX-H exactly:

```bash
trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT
trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 130' INT
trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 143' TERM
```

EXIT remains pure-cleanup so normal completion paths still disarm cleanly; INT/TERM cleanup and then exit so bash does not resume the interrupted function body.

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.
