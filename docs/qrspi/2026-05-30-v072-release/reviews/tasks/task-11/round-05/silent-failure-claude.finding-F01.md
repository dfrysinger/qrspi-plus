---
finding_id: R5-SF-F01-claude
reviewer: silent-failure-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
at_cap: false
escalate: false
duplicate_of: R5-SF-F01
---

# F01 MED — `_append_manifest_entry` mktemp failure uses `return 1` but callers ignore it; script exits 0 with no manifest entry written

**Introduced by R5 FIX-B (R5).**

## What the code does

FIX-B introduced a `mktemp` call inside `_append_manifest_entry` at lines 307–312
that uses `return 1` on failure, while every other error path in the same function
uses `exit 1` (lines 321, 330, 340, 348).

Both callers (`emit_dispatch_manifest_entry` line 390, `emit_first_party_manifest_entry`
line 421) propagate the return value unchecked, and both main-body call sites
(lines 921–922 first-party path, 992–993 third-party success path) follow with
unconditional `exit 0`. The script disables `set -e` (line 50 comment), so no
auto-abort.

## What goes wrong silently

When `mktemp` fails (full filesystem, exhausted per-directory entry limit,
`/tmp` restriction):

1. `echo "error: mktemp failed for manifest tmp" >&2` prints — only visible signal.
2. `_append_manifest_entry` returns 1; lock IS properly released, trap IS properly disarmed.
3. `emit_*` propagates return 1 implicitly.
4. Main script ignores return value, executes `exit 0`.
5. **Caller sees exit 0: dispatch appears to have succeeded.**
6. **Manifest has no entry for this dispatch. Round is not auditable.**

Direct contradiction of task DoD: "Manifest append behavior is atomic and
append-safe across multiple reviewer tags in one round." An exit 0 with a
missing entry is a false-success signal that violates the append-safe contract.

## Why this is new to R5

Before FIX-B, `_append_manifest_entry` used `local tmp="${manifest}.tmp.${BASHPID:-$$}"` —
pure variable assignment, cannot fail. Every error path in the pre-R5 function
used `exit 1`, and callers were safe to ignore return values. FIX-B introduced
the FIRST `return 1` path in the function.

## Stderr is insufficient diagnostic

Callers that check exit codes (orchestrators, CI pipelines, test harnesses) see 0
and log a successful dispatch. Stderr can be suppressed by harnesses that
redirect to /dev/null (as the new FIX-C and FIX-D tests do: `>/dev/null 2>/dev/null`).
Audit trail silently broken without machine-detectable signal.

## Minimal fix

Replace `return 1` with `exit 1` at line 312 to be consistent with every other
error path in `_append_manifest_entry`:

```bash
if ! tmp="$(mktemp "${manifest}.tmp.XXXXXX")"; then
  echo "error: mktemp failed for manifest tmp" >&2
  trap - EXIT INT TERM
  rmdir "$_lock_dir" 2>/dev/null || true
  eval "$_saved_opts"
  exit 1          # consistent with all other error paths in this function
fi
```

## Cross-reference

Same root-cause defect as `silent-failure-codex.finding-F01.md` (R5-SF-F01) and
`security-codex.finding-F01.md` (R5-SEC-F01). Three independent reviewers
converged on this finding — strong signal.

## Other R5 fixes cleared

- FIX-D: `( ... ) || true` correctly preserves stderr, `$_dispatch_exit` captured before subshell.
- FIX-E: All 6 exit paths in `_append_manifest_entry` properly disarm trap before exit; INT/EXIT double-rmdir harmless.
- FIX-A: All 3 first-party prompt failure paths handle cleanup correctly.

(Persisted by orchestrator — claude-sonnet-4.6 returned chat-only on this dispatch.)
