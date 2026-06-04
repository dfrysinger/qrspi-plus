---
finding_id: R3-F03
reviewer_tag: silent-failure-claude
round: 3
task: 12
severity: low
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F03 — `RC_VALUE` bash fallback `|| echo 0` silently converts drain failure to success

## Location

`scripts/await-round.sh:293`

```bash
RC_VALUE="$(cat "$RC_FILE" 2>/dev/null || echo 0)"
```

## What goes wrong

Python writes `str(final_rc)` (e.g., `"1"` on failure) to `$RC_FILE` and exits 0. The `py_rc` guard only catches Python-process failures; it does not guard against `$RC_FILE` being unreadable after a successful Python exit. If `cat "$RC_FILE"` fails (concurrent removal, OS issue), the fallback `echo 0` makes `await-round.sh` exit 0 — success — even though Python recorded a drain failure. Race window is narrow but the `|| echo 0` pattern is a textbook silent-fallback.

## Fix

```bash
RC_VALUE="$(cat "$RC_FILE" 2>/dev/null || echo 1)"
```

Or assert and exit:

```bash
if [ ! -f "$RC_FILE" ]; then
  echo "await-round: internal error — RC_FILE not found after python drain" >&2; exit 1
fi
RC_VALUE="$(cat "$RC_FILE")"
```
