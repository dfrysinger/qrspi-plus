---
finding_id: F01
reviewer: silent-failure-claude
model: claude-sonnet-4.6
round: 6
task: 11
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh:279-320
---

# silent-failure-claude — task-11 round-06 — F01 (LOW)

**Stale `_manifest_tmp` relay: one-statement window between mktemp and relay assignment orphans tmpfile on signal.**

## R6's stated guarantee (comment at line 318–319)

> "Mirror tmp into the script-level relay so the EXIT/INT/TERM traps can clean it up if a signal fires after mktemp but before mv-promotion completes."

## The gap

The relay assignment (`_manifest_tmp="$tmp"`, line 320) happens *after* the traps are installed (lines 279–281, at lock-acquisition time) and *after* mktemp creates the file (line 311). Between mktemp completing and line 320 executing, `_manifest_tmp` still holds its pre-call value (`""` after a clean previous call). If a signal arrives in this window:

1. The INT/TERM/EXIT trap fires with `_manifest_tmp=""` → `rm -f ""` is a no-op
2. The tmpfile `/path/.dispatch-manifest.json.tmp.ABCDEF` created by mktemp is **not deleted**
3. The script exits 130/143 (non-zero — so the signal itself is visible to the caller)
4. The orphaned `.tmp.XXXXXX` file persists in the manifest directory until manual cleanup

## Why it matters

R6's claim that "tmpfile is cleaned up even when a signal fires after mktemp but before mv-promotion completes" is not fully satisfied. The window is narrow (a single bash assignment statement) but non-zero, and the consequence is an accumulating set of orphaned tmpfiles in the output directory that are never automatically swept.

## Suggested fix

Move the relay assignment immediately after the `mktemp` call but *before* any subsequent operations — and ideally reset the relay to `""` explicitly at the start of the lock-held block (not just at the end of prior calls) to make the "clean slate" invariant explicit:

```bash
# At lock acquisition — reset relay to ensure prior-call stale value is gone
_manifest_tmp=""
trap 'rm -f "$_manifest_tmp" 2>/dev/null || true; ...' EXIT
...

# Immediately after mktemp — minimize the window
if ! tmp="$(mktemp "${manifest}.tmp.XXXXXX")"; then
  ...
  exit 1
fi
_manifest_tmp="$tmp"   # ← move here (already is here, but reset above is missing)
```

The reset at lock-acquisition (`_manifest_tmp=""`) ensures the trap's first reference to the relay is always `""` rather than whatever an interrupted prior call left. Then the relay is set as early as possible. The window cannot be fully eliminated in bash (mktemp is a subprocess), but the explicit reset removes the additional hazard of stale-path-from-prior-call cleanup attempts.

## Disposition note

The consequence is exclusively a resource leak (orphaned tmpfiles, not manifest corruption). The script exits non-zero (130/143) so the caller can observe the failure. This does not reopen the R5 audit-trail silent-break — the manifest was never written (mv hadn't run), so there is no phantom entry.

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.
