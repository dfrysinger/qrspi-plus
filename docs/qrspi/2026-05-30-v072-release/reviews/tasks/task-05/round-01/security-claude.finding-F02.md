---
finding_id: F02
reviewer_tag: security-claude
round: 1
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:205-206
artifact: tests/unit/test-change-type-partition.bats
---

# TOCTOU Race Between `rm -rf "$dest"` and `cp -R "$src" "$dest"` Allows Symlink Injection

Materialized from chat-only response by claude-sonnet-4.6.

```bash
rm -rf "$dest"       # window opens here
cp -R "$src" "$dest" # window closes here
```

Between `rm` and `cp`, `$dest` does not exist. An attacker on the same machine can create a symlink at `$dest` pointing to an arbitrary directory before `cp -R` executes. `cp -R` follows the symlink and writes fixture files into the symlink target rather than the tmpdir.

Also affects parallel-bats: two test functions calling `_run_fan_in_on_fixture` with the same fixture dirname could collide if BATS reuses a tmpdir parent.

Fix: use `mktemp -d "$BATS_TEST_TMPDIR/fixture-XXXXXX"` to create a unique destination, eliminating both the TOCTOU window and the namespace collision.
