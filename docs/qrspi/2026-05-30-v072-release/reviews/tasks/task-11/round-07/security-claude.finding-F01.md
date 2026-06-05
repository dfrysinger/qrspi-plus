---
finding_id: F01
reviewer: security-claude
model: claude-sonnet-4.6
round: 7
task: 11
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh:922-930
---

# security-claude — task-11 round-07 — F01 (LOW)

## Pre-trap race window leaves orphaned empty tmpfile (resource leak, not a disclosure)

**What the code does:**
```bash
922: _fp_tmp=""
923: if ! _fp_tmp="$(mktemp "${_fp_prompt_file}.tmp.XXXXXX")"; then
924:   ...
926: fi
930: trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM
931: if ! compose_prompt > "$_fp_tmp"; then
```

**The gap:** Between line 923 (mktemp returned, `_fp_tmp` set) and line 930
(trap installed), a pending SIGINT/SIGTERM is deliverable. If it fires:
- `_fp_tmp` holds the path to a freshly-created empty tmpfile.
- No cleanup trap is yet in place.
- Script exits, leaving the empty file orphaned at
  `<round-dir>/.dispatch/<tag>.prompt.tmp.XXXXXX`.

**Why this is NOT a data-disclosure:** `compose_prompt` has not yet run — the
tmpfile is empty. Subject code only flows into the file at line 931, which
is *after* the trap is installed. The trap correctly covers the entire
subject-code-present window.

**Why it differs from `_manifest_tmp` (the claimed mirror):** Manifest pattern
installs the trap *before* mktemp (line 288), with relay = `""`. `_fp_tmp`
inverts this. The comment at line 927 says "Mirror of the _manifest_tmp
relay+trap pattern" but the ordering is reversed.

## Recommended fix

Install the trap before mktemp, with relay already `""`:
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

This is the exact `_manifest_tmp` pattern AND addresses the exit-code masking
ancillary observation (3 separate traps with exit-130/143 preserve signal
exit codes, matching FIX-H lines 288-290).

## Nested-context analysis (per R7 scope hint): NO ISSUES

Checked exhaustively — see review summary for matrix. Script error branches
at 932 and 938 already cleanup + disarm + exit 1, so the codex HIGH claim
that "script announces dispatch with file missing" cannot occur: only path to
line 948 is via mv-f success, in which case the file IS at $_fp_prompt_file.

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.
