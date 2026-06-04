# F04 — Script-boundary guard test masks grep errors with `2>/dev/null || true` → false-pass if scripts/ is absent/renamed

**Category:** 1 — Swallowed Errors (in test setup → false-pass)
**Severity:** Low
**File:** `tests/unit/test-scope-tagger-dispatch.bats` — "[T13] scripts/ contain NO first-party Task-tool subagent dispatch" (diff L307-319)

## What happens

```bash
hits="$(grep -rnE 'subagent_type|Task\(|Agent\(' "$REPO_ROOT/scripts/" 2>/dev/null || true)"
if [ -n "$hits" ]; then ... return 1; fi
```

`grep` returns 0 (match), 1 (no match), or **2 (error: path missing, permission denied,
unreadable)**. The `2>/dev/null || true` swallows the error stream *and* the exit status, so
exit 2 is indistinguishable from exit 1 — both yield `hits=""` and the test passes green.

## Why this is a silent failure

This is an architectural-boundary **regression guard**. Its whole value is failing when the
boundary is violated. But if `$REPO_ROOT/scripts/` is ever missing, moved, or renamed —
note T20 (a downstream blocker named in task-13.md line 14) renames the dispatch script and
touches `scripts/` — `grep` errors, the error is swallowed, and the guard **passes without
testing anything**. A genuine future migration of Task-tool dispatch into a relocated scripts
tree would not be caught. The guard would advertise green coverage while verifying nothing.

## Recommendation

Assert the directory exists and that grep exited 0 or 1 (not 2). For example:

```bash
[ -d "$REPO_ROOT/scripts" ] || { echo "scripts/ dir missing — guard cannot run"; return 1; }
hits="$(grep -rnE 'subagent_type|Task\(|Agent\(' "$REPO_ROOT/scripts/")"; rc=$?
[ "$rc" -le 1 ] || { echo "grep errored (rc=$rc)"; return 1; }
[ -z "$hits" ] || { echo "found: $hits"; return 1; }
```
