---
finding_id: R3-F03
reviewer: sf-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F03 — Manifest append ignores sed/printf/mv failures, silent persistence loss

**File:** scripts/run-codex-review.sh lines 227-235 (`_append_manifest_entry`)

The `sed`, `printf`, and `mv` calls inside `_append_manifest_entry` are not exit-checked. With only `set -u` enabled (no `set -e`), a failed `mv` (e.g., cross-filesystem, permission denied) or failed `sed` (malformed input) does not abort the function — the function still returns success if the final `rmdir` (lock release) succeeds.

Result: dispatch appears successful at the caller, but the manifest update is missing or malformed. The convergent runtime signal (exit 0) is wrong relative to the persisted state.

**Fix:** check each step explicitly:

```sh
sed ... > "$_tmp" || { _release_lock; return 1; }
mv "$_tmp" "$_manifest" || { _release_lock; return 1; }
```

Or wrap the body in a subshell with `set -e` so any failed step aborts the function. Either way, restore the lock-release path on the error branch.
