---
finding_id: R5-SEC-F01-claude
reviewer: security-claude
severity: low
change_type: regression
referenced_files:
  - scripts/run-codex-review.sh
at_cap: false
escalate: false
---

# F01 LOW — INT/TERM traps orphan mktemp tmpfile in OUTPUT_DIR

**Introduced by R5 FIX-E (split INT/TERM traps).**

## Summary

FIX-E split the manifest-lock INT/TERM traps to call `exit 130`/`exit 143`
after releasing the lock. The trap strings only clean up `$_manifest_lock_dir`
(the lock directory); they do not clean up the `$tmp` local variable set by
`mktemp` at line 307. When SIGINT or SIGTERM fires in the window after mktemp
creates the tmpfile and before the function's own rm-f/mv completes, the
tmpfile is orphaned in `$OUTPUT_DIR` indefinitely.

## Regression from pre-R5 behaviour

Pre-R5, the combined `trap '...rmdir...' EXIT INT TERM` did NOT call `exit`
on INT/TERM. Bash returned control to the interrupted function body, which
eventually reached either:
- a `rm -f "$tmp"` on any error path (lines 317, 326, 336, 344), or
- `mv "$tmp" "$manifest"` on the success path (line 342).

Either way the tmpfile was cleaned up by the function itself.

FIX-E's `exit 130`/`exit 143` terminates the script before any of those
cleanup lines execute. The EXIT trap then fires (triggered by the `exit`
inside the INT/TERM handler), but its string is also `rmdir "$_manifest_lock_dir"
2>/dev/null || true` — it too does not reference `$tmp`.

## Concrete attack scenario

An attacker who can send SIGINT to the review dispatch script (e.g. a
co-tenant on a shared CI runner, or any operator pressing Ctrl+C) while
`_append_manifest_entry` is executing the jq write (line 315 or 324) causes:

1. SIGINT fires → INT trap: lock dir removed, `exit 130`.
2. EXIT trap fires: second `rmdir` (noop, lock already gone).
3. Script exits 130. `$tmp` at `$OUTPUT_DIR/.dispatch-manifest.json.tmp.<XXXXXX>` remains on disk.
4. Repeated interrupts → unbounded accumulation of tmpfiles in OUTPUT_DIR.

## Severity rationale

LOW because no new data exposure (tmpfile contains a subset of the manifest
data already readable in the same directory), no privilege escalation path,
requires ability to send SIGINT. Primary impact is filesystem hygiene /
accumulated partial-state files.

## Recommended fix

Use a script-level variable as a relay for `$tmp`, and clean it up in the
INT/TERM trap strings (or in the EXIT trap which fires after INT/TERM's exit):

```bash
# After mktemp succeeds, mirror $tmp into a script-level variable:
_manifest_tmp="$tmp"

# Expand EXIT trap to cover both lock and tmpfile (simpler — handles all
# abnormal-exit paths including INT/TERM cascade):
trap 'rm -f "$_manifest_tmp" 2>/dev/null || true
      rmdir "$_manifest_lock_dir" 2>/dev/null || true' EXIT
```

Clear `_manifest_tmp=""` after the successful `mv` to prevent the EXIT
trap from attempting to remove the now-promoted manifest file.

(Persisted by orchestrator — claude-sonnet-4.6 returned chat-only on this dispatch.)
