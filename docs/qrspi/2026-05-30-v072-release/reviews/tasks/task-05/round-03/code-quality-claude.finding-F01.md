---
finding_id: F01
reviewer_tag: code-quality-claude
round: 3
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-change-type-partition.bats:286
artifact: tests/unit/test-change-type-partition.bats
---

# False `jq` precondition skip causes silent test omission on jq-free environments

## Location

`tests/unit/test-change-type-partition.bats` line 286:

```bash
command -v jq >/dev/null 2>&1 || skip "jq required (helper precondition)"
```

in the test `_run_fan_in_on_fixture dereferences fixture symlinks (sandbox prefix guard cannot be bypassed via symlink)`.

## Problem

This test's core assertions check filesystem properties only:

- `[[ -e "$FIXTURE_DEST/symlinked-claude.finding-F01.md" ]]` — file exists in the copy
- `[[ ! -L "$FIXTURE_DEST/symlinked-claude.finding-F01.md" ]]` — entry is not a symlink

Neither assertion requires `jq`. The test does not call `jq` directly, and the verdict of `scripts/verifier-fan-in.sh` (which may need `jq`) is intentionally suppressed with `|| true` — the test only cares about the post-copy state.

Tracing the helper path on a jq-free system:
1. `cp -RL "$src/." "$dest/"` — succeeds; symlink is dereferenced.
2. `bash scripts/verifier-fan-in.sh "$dest"` — may fail if the script needs `jq`; exit code captured in `RC=$?`, helper continues.
3. `FIXTURE_DEST="$(cd "$dest" && pwd -P)"` — succeeds regardless; `dest` still exists.
4. Helper returns 0 with `FIXTURE_DEST` set.
5. The `[[ -e … ]]` and `[[ ! -L … ]]` checks run and pass/fail correctly.

The `jq` skip therefore causes the test to silently skip on jq-free CI environments, leaving the `cp -RL` symlink-dereference behaviour untested there — the very hardening this R2 fix-cycle introduced.

## Inconsistency

The companion helper test `_run_fan_in_on_fixture surfaces pwd -P failure as non-zero` uses the same `_run_fan_in_on_fixture` call against the same canonical fixture and carries no `jq` skip, making the guard asymmetric across the two helper tests.

## Fix

Remove the `jq` skip from this test:

```bash
# Remove: command -v jq >/dev/null 2>&1 || skip "jq required (helper precondition)"
local outside="$BATS_TEST_TMPDIR/outside-target.txt"
…
```

The test is self-contained: it creates its own fixture in `$BATS_TEST_TMPDIR`, runs the helper with `|| true`, and then checks filesystem state. No `jq` dependency is present.

If a jq guard is needed for a future assertion within this test that does parse the audit JSON, add it at that point with a specific note explaining which assertion requires it.
