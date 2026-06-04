---
finding_id: F01
reviewer_tag: silent-failure-claude
round: 3
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:295-297
artifact: tests/unit/test-change-type-partition.bats
---

# `|| true` in symlink test swallows helper setup-failure codes on a false premise

## Location

`tests/unit/test-change-type-partition.bats` lines 295–297 (new test added in R3):

```bash
_run_fan_in_on_fixture "$src" \
    || true  # the helper may exit non-zero on this synthetic fixture; we
             # care about the post-copy state, not the script's verdict.
```

## Root cause: the comment's premise is factually wrong

The justifying comment says "the helper may exit non-zero … on this synthetic fixture". This is incorrect. `_run_fan_in_on_fixture` captures the fan-in **script's** verdict internally:

```bash
RC=0
bash scripts/verifier-fan-in.sh "$dest" \
    >"$BATS_TEST_TMPDIR/fan-in.stdout" 2>"$BATS_TEST_TMPDIR/fan-in.stderr" \
    || RC=$?
```

The fan-in script's exit code is stored in `RC`; it does **not** propagate to the helper's own return code. The helper returns non-zero **only** for setup failures:

| Return code | Cause |
|-------------|-------|
| 99 | Fixture directory missing |
| 98 | Unsafe/path-traversal basename |
| 97 | `mktemp` failed |
| 96 | `cp -RL` failed |
| 95 | `pwd -P` resolve failed / FIXTURE_DEST empty |

Therefore `|| true` is not guarding against a fan-in-script verdict — it is unconditionally swallowing the helper's own named setup-failure signals.

## Silent-failure impact

**Current code:** The `[[ -n "$FIXTURE_DEST" ]]` guard on line 298 catches all *current* setup failure paths (FIXTURE_DEST is only written at the very end of the helper, so any earlier return leaves it unset/empty). The test will therefore fail rather than silently pass under current code. However:

1. **Diagnostic quality is degraded.** When a setup failure fires (e.g. `cp -RL` fails with return 96), the helper prints `"cp -RL failed for …"` to stderr and returns 96. The `|| true` swallows the 96; the test fails much later with `"FIXTURE_DEST empty"` — obscuring the real cause and making CI failures harder to diagnose.

2. **Explicit contract is violated.** The helper's own docstring states: *"Every call site MUST check the helper's return code so an environment-setup failure … surfaces with a named diagnostic instead of being silently coerced to RC=0 downstream."* `|| true` coerces every non-zero return to RC=0 downstream — precisely the anti-pattern the contract forbids.

3. **Latent maintenance risk.** A future change to the helper that sets `FIXTURE_DEST` before a new failure condition (e.g. a post-copy validation step) could cause this test to silently pass while standing in a partially-set-up sandbox. The `[[ -n "$FIXTURE_DEST" ]]` guard would not catch a non-empty-but-wrong `FIXTURE_DEST`.

4. **The pwd override test (lines 253–277) — added in the same R3 diff — deliberately pins return code 95** to prevent a future `|| true` re-introduction from masking failures. The symlink test directly undercuts that protection at the call site level.

## Fix

Remove `|| true`. The helper never returns non-zero for the fan-in script's verdict (that is captured in `RC`), so the suppression serves no purpose. Fail loudly on any setup error:

```bash
# Before:
_run_fan_in_on_fixture "$src" \
    || true

# After: honor the helper contract
_run_fan_in_on_fixture "$src" \
    || { echo "fixture setup failed (exit $?)" >&2; return 1; }
```

If the intent is truly to tolerate a known setup-failure code for some test reason, capture and assert the specific code rather than blanket-suppress:

```bash
local setup_rc=0
_run_fan_in_on_fixture "$src" || setup_rc=$?
# assert setup_rc is one of the acceptable values, not blanket || true
```

The `[[ -n "$FIXTURE_DEST" ]]` guard on the next line can be kept as defense-in-depth but should not substitute for checking the return code the helper was designed to surface.
