---
finding_id: R5-CQ-CLAUDE-F02
reviewer: code-quality-claude
severity: low
change_type: style
referenced_files:
  - scripts/run-codex-review.sh
at_cap: false
escalate: false
---

# F02 — `return 1` vs `exit 1` inconsistency in `_append_manifest_entry` mktemp failure path

**Introduced by R5 FIX-B.**

## Location

`scripts/run-codex-review.sh` — inside `_append_manifest_entry`, the new
mktemp failure path (added by FIX-B, approximately the block beginning
`if ! tmp="$(mktemp "${manifest}.tmp.XXXXXX")"`):

```bash
if ! tmp="$(mktemp "${manifest}.tmp.XXXXXX")"; then
  echo "error: mktemp failed for manifest tmp" >&2
  trap - EXIT INT TERM
  rmdir "$_lock_dir" 2>/dev/null || true
  eval "$_saved_opts"
  return 1            # ← uses return 1
fi
```

All other error-exit paths in the same function (jq-append-failed,
jq-init-failed, jq-type-check-failed, mv-failed) use `exit 1` after
the same cleanup sequence (`trap -`, `rmdir`, `eval "$_saved_opts"`).

## Defect

The inconsistency is not a correctness bug in the current codebase:
`eval "$_saved_opts"` restores `set -e` before `return 1`, so the
caller's errexit propagates the failure to the script level in the same
way `exit 1` would.  Both paths result in the script exiting non-zero
with an error already printed.

However, the inconsistency creates a maintenance trap:

1. A future reader sees `return 1` and may infer the caller handles the
   failure gracefully (the conventional reason to use `return` instead
   of `exit`).  Neither `emit_dispatch_manifest_entry` nor
   `emit_first_party_manifest_entry` check `_append_manifest_entry`'s
   return status.

2. If `set -e` were ever disabled at a call site (e.g. a new `|| true`
   wrapper added around one of the emit functions), `return 1` would
   silently swallow the mktemp failure while the `exit 1` paths would
   still terminate the script.  The inconsistency makes this asymmetry
   invisible.

## Recommended fix

Change `return 1` to `exit 1` to match every other error-exit path in
the function:

```diff
-  return 1
+  exit 1
```

If the intent was to allow the caller to retry or ignore a mktemp
failure (which no caller currently does), add a comment explaining that
intent; otherwise the consistent `exit 1` is the right choice.
