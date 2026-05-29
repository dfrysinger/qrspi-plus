---
finding: F01
reviewer: cq-claude
round: 2
task: task-03
severity: low
change_type: style
file: tests/helpers/skill-markdown.bash
lines: 236
persistence_note: orchestrator-persisted (round-02 subdir did not exist at dispatch; reviewer chat-only fallback)
---

# Hardcoded `/tmp` path — use `${TMPDIR:-/tmp}` for portability

## Location

`tests/helpers/skill-markdown.bash` line 236:

```bash
local signal_tmp="/tmp/skill-md-fence-signal-$$"
```

## Issue

The signal-file path is hardcoded to `/tmp`. On macOS (Darwin), the OS sets `TMPDIR` to a session-specific path (e.g., `/var/folders/...`). The comment on this same line acknowledges concurrent-caller safety via `$$` scoping but misses cross-environment portability.

If `/tmp` is restricted or not writable in a CI sandbox, `awk`'s `print ... > signal_tmp` silently fails, causing every call to fall through to the `*` wildcard case and emit "not found" even when the anchor exists and has content — a silent correctness failure with a misleading error message.

## Fix

```bash
local signal_tmp="${TMPDIR:-/tmp}/skill-md-fence-signal-$$"
```

This is the POSIX-portable idiom for temp files and matches what `mktemp` uses on macOS by default.
