---
reviewer: security-claude
task: 4
round: 2
status: clean
---

# Security Review — Task 04 Round 2 — Clean

## Scope reviewed

- `tests/unit/test-change-type-partition.bats` (R1 fix-cycle diff at 2cef825)
- `skills/reviewer-protocol/SKILL.md` (unchanged in this round's diff; spot-checked for new injection sinks — none added)

## R1 finding closure: CWE-377 / CWE-379 tempfile risk

The R1 finding flagged `2>/tmp/ct-stderr-$$.log` followed by `cat /tmp/ct-stderr-$$.log; rm -f /tmp/ct-stderr-$$.log` as:

- **CWE-377** Insecure Temporary File — writing to a path in the shared sticky-bit `/tmp` directory.
- **CWE-379** Creation of Temporary File in Directory with Insecure Permissions — predictable name (`ct-stderr-<pid>.log`) where a co-located attacker can pre-create a symlink so the `2>` redirect clobbers an arbitrary user-writable target (e.g. `~/.ssh/authorized_keys`, dotfiles, an in-development source file the test runner owns).
- **CWE-367** TOCTOU — the `rm -f` between write and read races against the same attacker.

The R2 fix at lines 98–99 replaces both occurrences with `$BATS_TEST_TMPDIR/ct-stderr.log`. This closes the issue because:

1. `BATS_TEST_TMPDIR` is provisioned by bats-core as a mode-0700 per-test directory under a private parent (not the world-writable `/tmp` root); a non-privileged co-located attacker cannot enter it or pre-create entries inside it.
2. The filename no longer encodes `$$`, removing the predictable-name component that made the symlink-precreate attack feasible.
3. Bats handles cleanup at test teardown, eliminating the manual `rm -f` TOCTOU window.
4. Both the redirect target and the `cat` argument are double-quoted, so even pathological `$BATS_TEST_TMPDIR` values (defense in depth) cannot word-split into argv injection.

I verified no other tempfile site in the file still references `/tmp` or `$$`.

## Additional surfaces audited in scope, no findings

- **Injection sinks.** The `awk` invocations (lines 37–38, 72–76) and `grep -qE` calls (lines 90–91, 121, 129–132, 142–145, 166) operate on repository-tracked fixture and skill paths, not on attacker-controlled input. No command, template, regex, or path-traversal sink reachable from untrusted input.
- **Regex DoS.** All `grep -qE` patterns are bounded and operate on small repo-tracked text; no catastrophic-backtracking shape against attacker-influenced input.
- **Scope-audit hardening (line 162).** The change from silent `continue` to loud `return 1` on a missing required file is a correctness hardening; the iterated array is a hardcoded allow-list, so no new path-traversal or arbitrary-file-read surface is introduced.
- **Data exposure.** Stderr capture is to a per-test private tmpdir and is consumed by the same test process for assertion; no secrets, tokens, or PII flow through these paths.
- **Auth / access control / crypto / deps.** Not applicable to a bats unit test of a frontmatter-parsing schema mirror.

## Result

R1 tempfile finding is closed. No new security findings in R2.
