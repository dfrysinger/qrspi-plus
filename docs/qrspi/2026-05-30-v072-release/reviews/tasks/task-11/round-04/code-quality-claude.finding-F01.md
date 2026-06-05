---
finding_id: code-quality-claude.finding-F01
severity: low
change_type: style
reviewer: code-quality-claude
round: 4
file: scripts/run-codex-review.sh
line: 280
at_cap: true
---

# Missing `local` declaration for `_lock_age` in `_append_manifest_entry`

## Location

`scripts/run-codex-review.sh`, line 280, inside `_append_manifest_entry`.

## Description

Inside the stale-lock probe block of `_append_manifest_entry`, two adjacent
temporaries are correctly declared with `local`, but the derived variable
`_lock_age` is not:

```bash
local _now; _now=$(date +%s)                                    # ✓ local
local _mtime; _mtime=$(stat -f %m "$_lock_dir" 2>/dev/null ...) # ✓ local
_lock_age=$(( _now - _mtime ))                                   # ✗ MISSING local
```

Every other temporary in this function uses `local` (`_saved_opts`, `entry`,
`manifest`, `_lock_dir`, `_lock_attempt`, `tmp`).  The omission here is
inconsistent with the surrounding code.

Because `_lock_age` is not declared `local`, it leaks into the caller's scope
after `_append_manifest_entry` returns.  In practice this is benign — the
leading-underscore name is unlikely to collide with anything in the
non-function script body — but it violates the convention established by every
other variable in the function and is the kind of scope-leak that becomes
meaningful if the function is ever sourced and called from a context that
declares its own `_lock_age`.

## Fix (if user authorizes cap-bend)

```bash
# line 280
local _lock_age; _lock_age=$(( _now - _mtime ))
```

## At-cap escalation note

This is a cycle-3-of-3 at-cap finding.  No R5 fix-cycle fires automatically.
The fix is a one-line `local` addition.  User must explicitly authorize a
cap-bend to address it, or carry it forward as a polish item in a future task.
