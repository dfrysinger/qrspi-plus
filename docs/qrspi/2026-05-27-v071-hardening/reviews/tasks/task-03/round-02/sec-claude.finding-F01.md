---
finding: F01
reviewer: sec-claude
round: 2
task: task-03
severity: low
change_type: correctness
file: tests/helpers/skill-markdown.bash
lines: 236-278
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F01 — Predictable temp-file path enables TOCTOU / forced-success attack

## Location

`tests/helpers/skill-markdown.bash` line 236:

```bash
local signal_tmp="/tmp/skill-md-fence-signal-$$"
```

## Finding

The signal file that carries the awk-to-shell result (`FOUND_WITH_CONTENT` / `FOUND_EMPTY`) is created at a path that is **fully predictable** before the process starts: `/tmp/skill-md-fence-signal-<PID>`. `$$` is the main shell PID (not the subshell PID), and on Linux/macOS PIDs are allocated sequentially and are observable to any process on the same host.

Two concrete attacks apply on a shared CI server where `/tmp` is world-writable:

### Attack A – forced test-pass (integrity)

1. Adversary process polls `ps`/`/proc` to learn the next PID or races process creation during `bats` parallel execution.
2. It `touch`es `/tmp/skill-md-fence-signal-<PID>` and writes `FOUND_WITH_CONTENT` into that file before `awk` runs.
3. On a race condition the pre-written content survives.
4. Result: `extract_section_fence_aware` reads `FOUND_WITH_CONTENT` and **returns 0** even when the anchor section is absent. Security review tests that assert on the extracted section silently pass on empty output.

### Attack B – arbitrary file write (limited impact)

1. Adversary creates a symlink: `ln -sf /path/to/sensitive /tmp/skill-md-fence-signal-<PID>`
2. awk's END block follows the symlink, writing the string to the symlink target.

## Why this matters in context

This function is a **test helper that gates correctness of security-review pipelines**. A forced `return 0` on a missing anchor means reviewer-prompt checks silently pass on empty strings, defeating the contract they are meant to enforce.

## Recommended fix

Use `mktemp`:

```bash
local signal_tmp
signal_tmp="$(mktemp "${TMPDIR:-/tmp}/skill-md-fence-signal-XXXXXXXX")"
```

`mktemp` creates the file with mode 0600 and an unguessable suffix, eliminating both the prediction race and the pre-creation window.

## Other scoped concerns (all clean)

- Command injection via awk `-v anchor=`: clean (`-v var=value` is string assignment)
- Path traversal in `$file`: clean (passed as positional argument)
- Fence-state confusion: clean (toggle is symmetric)
- Control-character leakage: clean (`printf %s`)
