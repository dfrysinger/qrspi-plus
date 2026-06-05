---
finding_id: R4-F02
reviewer: sec-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F02 — `_append_manifest_entry` tmp path uses predictable PID + no O_EXCL → symlink clobber primitive even inside the lock

**File:** scripts/run-codex-review.sh ~lines 298-310 (the `tmp="${manifest}.tmp.${BASHPID:-$$}"` + `jq ... > "$tmp"` block introduced/preserved in R4 Group D).

Pattern:
```bash
tmp="${manifest}.tmp.${BASHPID:-$$}"
jq --argjson new "$entry" '. + [$new]' "$manifest" > "$tmp"
mv "$tmp" "$manifest"
```

The lock prevents concurrent writers from racing each other, but does NOT prevent an attacker with write access to `OUTPUT_DIR` from pre-placing symlinks at predictable temp paths:

1. Attacker enumerates likely PID values (bash `$$` of orchestrator subshells is enumerable; `BASHPID` of `_append_manifest_entry` subshell is also enumerable from `/proc` or by spawning).
2. Attacker creates `.dispatch-manifest.json.tmp.<predicted-pid>` as a symlink to `~/.bash_profile` (or any user-writable target).
3. When our code runs in a subshell matching that PID, `jq ... > "$tmp"` follows the symlink and writes jq's stdout (a JSON array containing manifest content + new entry) to the target.

Result: arbitrary file overwrite primitive with attacker-influenceable content (the manifest contains REVIEWER_TAG, OUTPUT_DIR, prompt_file paths). JSON-shaped content overwriting a shell rc file produces parse errors, not code execution — but if the attacker can predict timing, a manifest entry with carefully crafted strings could be injected into other consumed files.

**Why the lock doesn't help:** the lock serializes our own writers but doesn't prevent the symlink-target from existing before we acquire the lock. Pre-placement happens once; the lock just ensures only one of our writes hits the trap at a time.

**Fix (use mktemp for the tmp inside the lock too):**
```bash
tmp="$(mktemp "${manifest}.tmp.XXXXXX")" || {
  rmdir "$_lock_dir" 2>/dev/null
  echo "error: mktemp for manifest tmp failed" >&2
  exit 1
}
if ! jq --argjson new "$entry" '. + [$new]' "$manifest" > "$tmp"; then
  rm -f "$tmp"
  rmdir "$_lock_dir" 2>/dev/null
  echo "error: jq append failed" >&2
  exit 1
fi
# Validate output is parseable JSON array before clobbering (already present)
# mv (rename(2)) atomically replaces; if dest is a symlink, dest is replaced
if ! mv -f "$tmp" "$manifest"; then
  rm -f "$tmp"
  rmdir "$_lock_dir" 2>/dev/null
  echo "error: mv failed" >&2
  exit 1
fi
```

Same fix shape as F01 (mktemp + mv). Apply both. Note `mv -f` is required: without `-f`, mv refuses to overwrite an existing destination on some platforms when the destination is a symlink to a non-writable file.

**Severity MED** (not HIGH like F01) because the written content is JSON-formatted manifest data rather than attacker-controlled shell text — the immediate impact is data corruption / partial information disclosure rather than direct RCE. Still an arbitrary-file-clobber primitive that shouldn't ship.
