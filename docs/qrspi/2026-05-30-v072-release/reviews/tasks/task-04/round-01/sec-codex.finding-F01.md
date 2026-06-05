---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:87-88"]
artifact: code
round: 1
reviewer: security-codex
---

**Predictable `/tmp` filename allows symlink clobber/race in test execution.**

`2>/tmp/ct-stderr-$$.log` is vulnerable to symlink race on shared runners. Pre-created symlinks for likely PIDs can cause shell redirection to overwrite arbitrary files owned by the test user.

**Fix:** Use `mktemp` or Bats helpers like `$BATS_TEST_TMPDIR` and strict permissions.

Materialized from chat-only Codex output.
