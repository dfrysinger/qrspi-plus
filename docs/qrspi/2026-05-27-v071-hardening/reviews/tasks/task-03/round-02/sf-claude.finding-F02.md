---
finding: F02
reviewer: sf-claude
round: 2
task: task-03
severity: low
change_type: correctness
file: tests/helpers/skill-markdown.bash
lines: 236, 276-279
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F02 — signal temp file leaks on process interruption; no EXIT trap

## Location

`tests/helpers/skill-markdown.bash` lines 236 and 276–279 (`extract_section_fence_aware`)

## What the code does

```bash
local signal_tmp="/tmp/skill-md-fence-signal-$$"
# ...
if [ -r "$signal_tmp" ]; then
  signal="$(cat "$signal_tmp")"
  rm -f "$signal_tmp"     # only cleanup point
fi
```

No `trap … EXIT` to ensure cleanup if interrupted (SIGINT, SIGTERM, or `set -e`).

## Silent failure path

On interrupt, `/tmp/skill-md-fence-signal-$$` is left on disk. Within the same process: every call to `extract_section_fence_aware` uses the **same** file name (`$$` does not change). If a previous call's `rm -f` was skipped (interrupt scenario), the next call could read a stale signal.

## Recommended fix

```bash
trap 'rm -f "$signal_tmp"' EXIT
```

Or use `mktemp` so each invocation gets a unique path (also resolves sec.F01).
