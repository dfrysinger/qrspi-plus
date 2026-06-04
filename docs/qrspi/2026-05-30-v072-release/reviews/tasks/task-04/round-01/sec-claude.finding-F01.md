---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:87-88"]
artifact: code
round: 1
reviewer: security-claude
---

**Insecure temp-file pattern (CWE-377/CWE-379) in new schema-guard regression test.**

`2>/tmp/ct-stderr-$$.log` with no `mktemp`, no `$BATS_TMPDIR`, no symlink check; trailing `rm -f` on same path. Local attacker on shared CI/dev host can pre-plant symlinks `/tmp/ct-stderr-<PID>.log → ~/.ssh/authorized_keys` (or similar) — when bats subshell PID matches, the `2>` redirect truncates and writes attacker-chosen files with test-user privileges. `rm -f` then hides the symlink.

**Fix:** One-line change to `$BATS_TEST_TMPDIR/ct-stderr.log` or `mktemp`. No DoD or scope impact.

Materialized from chat summary.
