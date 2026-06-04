---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:L87-L88"]
artifact: task-04
round: 1
reviewer: security-claude
---

# Insecure temp-file pattern in new schema-guard regression test (CWE-377)

## Location

`tests/unit/test-change-type-partition.bats:L87-L88` (new code in this diff):

```bash
out=$(_partition_finding "$fixture" 2>/tmp/ct-stderr-$$.log) && rc=0 || rc=$?
err=$(cat /tmp/ct-stderr-$$.log); rm -f /tmp/ct-stderr-$$.log
```

## What's wrong

The test redirects stderr into a path on the world-writable `/tmp`
directory whose only entropy is the bats process PID (`$$`). PIDs on
Linux/macOS are small integers (typically <100k), trivially enumerable.
The test:

1. Does not create the file via `mktemp` (no O_EXCL, no random suffix).
2. Does not check whether the path already exists or is a symlink before
   the shell opens it for writing via `2>`.
3. Does not honor `$BATS_TMPDIR`, which bats provides specifically to
   avoid this class of bug (per-test isolated tmpdir under
   `$BATS_RUN_TMPDIR`).
4. Cleans up with `rm -f`, which silently follows symlinks and unlinks
   whatever the symlink pointed to (compounding step 2).

This is the textbook CWE-377 ("Insecure Temporary File") /
CWE-379 ("Creation of Temporary File in Directory with Insecure
Permissions") pattern.

## Concrete attack scenario

Threat model: a local attacker with a shell account on a host that runs
this bats suite (shared CI runner, multi-tenant dev VM, shared lab
workstation).

1. Attacker enumerates plausible PIDs the bats subshell will receive
   (a few thousand pre-created symlinks is cheap) and pre-creates:

   ```
   ln -s /home/<test-user>/.ssh/authorized_keys /tmp/ct-stderr-<PID>.log
   ```

   or any other write-target owned by the test user — `~/.bashrc`,
   `~/.gitconfig`, etc.

2. The test suite runs as the test user. When the bats subshell PID
   matches a pre-planted symlink, the shell opens the symlink target
   for writing (`2>` truncates+writes). `_partition_finding`'s stderr
   ("schema-guard: missing required field 'change_type:' in …") gets
   written into `authorized_keys` / `.bashrc` / etc., **truncating
   and overwriting** the original file with attacker-influenced
   content. (Attacker controls the `$fixture` path portion of the
   diagnostic message via repo state, giving partial content control.)

3. The trailing `rm -f /tmp/ct-stderr-$$.log` then unlinks the symlink
   (leaving the corrupted target). Cleanup hides the trail.

Impact ranges from test-user file corruption to (with `authorized_keys`
trick) lateral movement on the test host. Bounded to test-user
privileges, but on shared/persistent runners that is meaningful.

## Why this matters even though it's "just a test"

- The task explicitly cites this test file as the regression surface
  that pins the field-name contract; it will run in CI on every PR for
  the lifetime of the project. The exposure window is permanent.
- The fix is a one-line mechanical change with no behavior delta — no
  scope expansion, no DoD touch.

## Fix

Replace both lines with the bats-provided per-test tmpdir:

```bash
out=$(_partition_finding "$fixture" 2>"$BATS_TMPDIR/ct-stderr.log") && rc=0 || rc=$?
err=$(cat "$BATS_TMPDIR/ct-stderr.log"); rm -f "$BATS_TMPDIR/ct-stderr.log"
```

`$BATS_TMPDIR` is created by bats per-test with mode 0700, eliminating
the symlink-race surface entirely. Alternatively use
`mktemp -t ct-stderr.XXXXXX` and quote-trap the resulting path.

## Scope justification (why this is in-bounds for T04 R1)

- The vulnerable lines are **new in this diff** (the bats helper was
  added by this task; pre-existing temp-file patterns in other tests
  are out of scope for this review).
- Categorized `correctness` (not `scope`) because the fix is purely a
  mechanical hardening of newly-added test scaffolding and does not
  alter any DoD assertion, fixture, or protocol wording — it does not
  push T05's surface.
- Not flagged on `_partition_finding`'s loose `awk` matching because
  the task's `Out:` list explicitly assigns enum hardening and the
  real verifier-fan-in script to T05.
