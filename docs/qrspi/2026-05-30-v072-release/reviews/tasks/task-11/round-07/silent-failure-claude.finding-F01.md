---
reviewer: silent-failure-claude
round: 7
finding: F01
severity: low
category: Missing Error Path / Partial State on Failure
status: open
files:
  - scripts/run-codex-review.sh:922-930
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2816-2829
---

# F01 — `_fp_tmp` cleanup trap installed AFTER mktemp, not before (inverts the stated `_manifest_tmp` pattern)

## Summary

FIX-M installs the `_fp_tmp` signal-cleanup trap (line 930) **after** the
`mktemp` call that creates the file (line 923).  This leaves a ~7-line window
(lines 923–930) where SIGINT/SIGTERM arrives with no active cleanup trap,
orphaning the mktemp'd tmpfile.  The code comment calls this "Mirror of the
`_manifest_tmp` relay+trap pattern", but the `_manifest_tmp` pattern
installs its trap **before** mktemp (trap at lines 288–290, mktemp at line 320).
`_fp_tmp` inverts this order.

## Exact window

```
922:   _fp_tmp=""
923:   if ! _fp_tmp="$(mktemp "${_fp_prompt_file}.tmp.XXXXXX")"; then  ← mktemp creates file
924:     echo "error: mktemp failed for first-party prompt tmpfile" >&2
925:     exit 1
926:   fi
    ← ← ← ← ← SIGNAL HERE: _fp_tmp is set, but no trap is installed ← ← ← ←
930:   trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM         ← too late
```

If SIGINT/SIGTERM fires between line 923 (mktemp succeeds, `_fp_tmp` assigned)
and line 930 (trap installed), bash exits via its default handler and the
file created by mktemp is left on disk unreferenced.

At this exact window the file is empty (compose_prompt has not run yet), so
there is no sensitive subject-code leak — but the resource is permanently
orphaned and the pattern is structurally incorrect.

## Contrast with `_manifest_tmp` (the correct pattern)

| Variable       | Trap installed        | mktemp called  | Order      |
|----------------|-----------------------|----------------|------------|
| `_manifest_tmp`| lines 288–290 (before)| line 320       | ✓ correct  |
| `_fp_tmp`      | line 930 (after)      | line 923       | ✗ inverted |

## Missing test coverage

The new test `"first-party prompt tmpfile has signal-cleanup trap on EXIT/INT/TERM"`
(bats line 2816) checks that the trap **exists** but does NOT verify that the
trap is installed **before** mktemp.  Compare with
`"manifest lock-held block resets _manifest_tmp before trap install"` which
correctly validates ordering via line-number comparison.  No equivalent
ordering test exists for `_fp_tmp`.

## Ancillary: INT/TERM traps do not propagate signal exit codes (informational)

The `_fp_tmp` trap body (`rm -f "$_fp_tmp" 2>/dev/null || true`) does not
call `exit 130`/`exit 143` for INT/TERM, unlike the `_manifest_tmp` traps.
Same defect surfaced as HIGH by sf-codex F01 and MED by sec-codex F01 this round.

## Recommended fix

Move the `trap` installation to **before** the `mktemp` call, mirroring the
`_manifest_tmp` pattern exactly, with 3 separate traps (EXIT pure-cleanup,
INT with exit-130, TERM with exit-143):

```bash
   _fp_tmp=""
   trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT
   trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 130' INT
   trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 143' TERM
   if ! _fp_tmp="$(mktemp "${_fp_prompt_file}.tmp.XXXXXX")"; then
     trap - EXIT INT TERM
     echo "error: mktemp failed for first-party prompt tmpfile" >&2
     exit 1
   fi
```

Add a companion ordering test (analogous to the `_manifest_tmp` one) asserting
the trap-install line number precedes the mktemp call line number.

## FIX-N status: CONFIRMED CLOSED

The R6 finding (`_manifest_tmp` stale-path orphan hazard) is correctly resolved.
`_manifest_tmp=""` reset at line 282 precedes trap install at 288–290, which
precedes mktemp at line 320. ✓
