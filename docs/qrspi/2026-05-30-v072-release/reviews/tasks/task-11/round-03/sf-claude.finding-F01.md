---
finding_id: R3-F01
reviewer: sf-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — _append_manifest_entry: mv exit code unchecked (silent write loss)

**Convergent with sf-codex R3-F03.** Same root cause: `mv "$tmp" "$manifest"` exit unchecked, falls through to rmdir which succeeds, function returns 0. Caller sees success; manifest is unchanged; tmp file left behind. Disk-full, NFS stale-handle, cross-device move all trigger this.

**Fix sketch:**
```bash
mv "$tmp" "$manifest" || {
  rmdir "$_lock_dir" 2>/dev/null
  echo "error: _append_manifest_entry: mv failed" >&2
  exit 1
}
```
