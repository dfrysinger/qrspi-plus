---
reviewer: code-simplifier-claude
task: 13
round: 4
finding: F01
severity: minor
blocking: false
category: dead-code
file: scripts/round-prepare.sh
lines: 192-199
---

## Dead pipe + write-only variable in the malformed-anchor check

`scripts/round-prepare.sh` L192-199 (Step 10 prior-artifact assertion, within
T13's changed lines):

```sh
  ANCHOR_CONTENT="$(cat "$PRIOR_ANCHOR_PATH" 2>/dev/null || true)"
  # Required shape: ^[0-9a-f]{40}\n$ (40-char SHA + single trailing newline).
  if ! printf '%s' "$ANCHOR_CONTENT" | python3 -c '
import sys
data = sys.stdin.buffer.read()
import re
sys.exit(0 if re.match(rb"^[0-9a-f]{40}\n$", data) else 1)
' < "$PRIOR_ANCHOR_PATH"; then
```

The `python3` invocation has its stdin redirected from the file via
`< "$PRIOR_ANCHOR_PATH"`. In POSIX shells the file redirect is applied after
the pipe, so it **supersedes** the pipe — `python3` reads the file contents,
not the `printf` output. That makes two things dead:

1. The `printf '%s' "$ANCHOR_CONTENT" |` pipe — its bytes are discarded
   before `python3` ever reads them.
2. `ANCHOR_CONTENT` (the L192 `cat`) — it is written but its only reader is
   the dead pipe, so it is now a write-only variable.

Worth noting the dead path is also *semantically* different from the live one:
`$(cat …)` strips trailing newlines, so `printf '%s' "$ANCHOR_CONTENT"` could
never satisfy the `\n$` anchor in the regex. The check works only because the
file redirect (the live input) carries the real trailing newline. So the
correct behavior is entirely owned by the `< "$PRIOR_ANCHOR_PATH"` redirect.

### Suggested simplification (semantics-preserving)

Drop the `cat` and the pipe, keep the file redirect:

```sh
  # Required shape: ^[0-9a-f]{40}\n$ (40-char SHA + single trailing newline).
  if ! python3 -c '
import re, sys
sys.exit(0 if re.match(rb"^[0-9a-f]{40}\n$", sys.stdin.buffer.read()) else 1)
' < "$PRIOR_ANCHOR_PATH"; then
```

This removes one process (`cat`), one write-only variable, and the misleading
dead pipe, while reading from exactly the same source the check already uses.
The missing-file case is still handled by the explicit `[ ! -f ... ]` guard at
L188, so dropping the `2>/dev/null || true` defensive `cat` loses nothing.

Non-blocking — round-4 thoroughness suggestion only.
