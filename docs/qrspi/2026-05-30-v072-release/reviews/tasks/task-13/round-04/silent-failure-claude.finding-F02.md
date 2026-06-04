---
finding_id: F02
reviewer: silent-failure-claude
task: 13
round: 4
severity: low
category: partial-state-on-failure
location: scripts/round-prepare.sh:228-237, 382-386, 419-423
---

## Anchor write precedes diff/sidecar emission — an I/O failure there leaves a stray `round-NN-commit.txt`

The round-4 fix correctly moves the anchor write *after* the Step 10 prior-artifact
presence assertions, so a missing/malformed prior anchor or empty prior scope-set
now leaves no stray current-round anchor — that part is verified clean (test at
diff lines 355–383 pins it).

However, the deferred anchor write at lines 228–237 still executes **before** the
two remaining write steps that can fail with exit 1:

- Step 7 diff emission — line 382: `if ! mv "$DIFF_TMP" "$DIFF_PATH"; then ... exit 1`.
- Step 8 sidecar emission — line 419: `if ! mv "$SIDECAR_TMP" "$SIDECAR"; then ... exit 1`.

If either `mv` fails (disk fills between the anchor write and the diff mv,
`$OUTPUT_DIR` becomes unwritable, etc.), the script exits 1 with the current-round
`round-NN-commit.txt` already on disk. The exit code is loud, so this is not a
true silent failure of the run — but it punctures the documented invariant that a
"failed verification leaves no round-NN-commit.txt on disk" (SKILL.md prose,
diff line 75/86). A round that aborts at diff/sidecar emission leaves an anchor
that the *next* round's Step 1 advance check (line 147–152) and Step 10 presence
assertion (line 186–204) will treat as evidence that round NN completed and was
reviewed — when in fact no diff/sidecar was produced and no reviewers ran.

Ask answered: if Step 7/8 fails halfway, the system is left with a commit anchor
implying a completed round that never happened.

Suggested fix: move the anchor write (lines 228–237) to after the successful
sidecar `mv` at line 423 (i.e., make the anchor the *last* artifact written, so it
is the commit point for the whole round), or have the diff/sidecar failure branches
`rm -f "$ANCHOR_PATH"` before `exit 1`. This keeps the "no anchor on any failed
preparation" invariant whole rather than only for the verification-phase failures.

Note: the relative ordering (anchor before diff/sidecar) predates this task's diff,
but T13 now owns the anchor-write placement, so closing the window here is in scope.
