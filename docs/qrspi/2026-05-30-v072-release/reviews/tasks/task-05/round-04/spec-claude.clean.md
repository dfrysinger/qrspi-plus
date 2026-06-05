---
reviewer: spec-claude
task: 5
round: 4
verdict: clean
---

# Spec Review — Task 05 Round 4: CLEAN

Both R4 changes are correctness fixes to the symlink-deref helper test and do not regress any T05 spec requirement.

## Changes verified

### 1. Removed false `jq` precondition (diff line −9)

`command -v jq >/dev/null 2>&1 || skip "jq required (helper precondition)"` was removed from the `_run_fan_in_on_fixture dereferences fixture symlinks` test.

**Why this is correct:** The symlink test asserts only post-copy filesystem state (`$FIXTURE_DEST` entry existence, symlink-vs-regular-file check). It never calls `jq`. The guard was a false precondition that could skip the test on `jq`-absent environments for no reason, masking the actual symlink-deref behavior. The appropriate `jq || skip` guards remain in place in every test that actually parses audit JSON (lines 316, 352, 397).

### 2. Removed `|| true` from `_run_fan_in_on_fixture "$src"` (diff lines −17/−18/−19, +21/+22/+23/+24/+25)

The `|| true` was silently absorbing rc 95-99 setup failures from the helper. The helper's contract reserves those codes for setup failures (missing fixture, bad basename, `mktemp`/`cp`/`pwd` errors) that must propagate. The fan-in script's pass/fail verdict on the synthetic fixture is captured internally in `$RC` (not asserted in this test); only the post-copy filesystem state is asserted. Removing `|| true` is the correct fix. The inline rationale comment accurately explains the distinction.

## T05 spec requirement coverage — unaffected

All five test expectations specified in T05 remain intact:

- Out-of-enum halt + audit (`change_type_out_of_enum`): lines 310–344 ✓
- All five canonical values accepted, kept-findings.txt, zero halts: lines 347–391 ✓
- Missing-field reported as `missing_change_type` (not out-of-enum): lines 393+ ✓
- Script-side single enum definition audit: present in file ✓
- Reviewer-protocol SKILL.md enum audit: lines 24–26 ✓
- Repository grep for no duplicated alternations: present in file ✓

No T05 requirement is regressed, removed, or reinterpreted. No out-of-scope files are modified.
