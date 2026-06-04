---
finding_id: R3-F02
reviewer: sf-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F02 — sed pattern silently corrupts manifest on trailing-newline-after-bracket

**Novel finding** (not convergent with any codex finding).

**File:** scripts/run-codex-review.sh line 228

```bash
if [[ -f "$manifest" ]]; then
  sed '$ s/\]$//' "$manifest" > "$tmp"
  printf ',\n  %s\n]\n' "$entry" >> "$tmp"
```

Two compounding issues:

**(a) Unchecked sed exit:** if sed fails (memory pressure, read error, write error to $tmp on disk pressure), $tmp is empty or partial; printf appends to corrupt content; the subsequent `mv` atomically replaces the valid manifest with malformed JSON. No warning. Every downstream jq consumer parse-fails.

**(b) Trailing-newline-after-bracket case:** if any prior writer left the manifest with a trailing newline after `]` (e.g., editor save, `echo "]"` instead of `printf "]"`), the sed `$` (last-line) anchor operates on the empty line AFTER `]`, not the line CONTAINING `]`. The `]` is silently NOT stripped. The subsequent `printf ',\n  ...\n]\n'` produces `]\n,\n  ...\n]\n` — double-closing-bracket, atomic-replaced over the valid file.

This is a real correctness bug independent of all the failure-handling issues. Repeated dispatch into a manifest that any other process has touched can produce silent corruption that downstream consumers only notice when jq fails.

**Fix:** use a content-aware strip:

```bash
# Strip the closing bracket from the last non-empty line that contains it
python3 -c '
import json, sys
manifest = sys.argv[1]
entry = sys.argv[2]
with open(manifest) as f:
    arr = json.load(f)
arr.append(json.loads(entry))
with open(sys.argv[3], "w") as f:
    json.dump(arr, f, indent=2)
' "$manifest" "$entry" "$tmp"
```

Or use jq to parse + append + emit (jq is already a dependency of the script):

```bash
jq --argjson new "$entry" '. + [$new]' "$manifest" > "$tmp"
```

`jq` is already used elsewhere in this script — the cost-of-shell-out is already paid. Replacing the sed/printf hack with `jq + .` is both correct and idiomatic.
