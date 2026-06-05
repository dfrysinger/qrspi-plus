---
finding_id: F03
reviewer_tag: code-quality-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:200-210
artifact: tests/unit/test-change-type-partition.bats
---

# Self-consistent defense gap: early-return in helper does not set RC, leaving success-path test with unset/empty RC

`_run_fan_in_on_fixture` contains a precondition guard that returns early if
the fixture directory is absent, but the guard does not set the `RC` variable
that all three callers use to evaluate the fan-in script's exit code:

```bash
_run_fan_in_on_fixture() {
  local src="$1"
  [[ -d "$src" ]] || { echo "fixture round missing: $src" >&2; return 99; }
  ...
  RC=0
  bash scripts/verifier-fan-in.sh "$dest" ... || RC=$?
}
```

When `[[ -d "$src" ]]` is false the function returns 99 (its own exit code)
**without ever reaching the `RC=0` assignment**.  Because BATS tests run in
subshells, `RC` starts as unset in each test.  After the helper returns early,
`$RC` is the empty string.

## The failure mode that matters: success-path test

The success-path test (the "all five canonical values" test) checks:

```bash
_run_fan_in_on_fixture tests/fixtures/change-type-enum/round-all-canonical

[[ "$RC" -eq 0 ]] \
  || { echo "expected exit 0 on canonical-enum round, got $RC"; ... }
```

In bash, `[[ "" -eq 0 ]]` is equivalent to `[[ 0 -eq 0 ]]` — the integer
comparison coerces the empty string to `0`.  This means **if the fixture
directory were absent, the test would silently pass the exit-code guard** and
proceed to the `[[ -f "$KEPT" ]]` check — where `$KEPT` is also unset.
`[[ -f "" ]]` is false, so the test would then fail with "expected
kept-findings.txt at " rather than with the informative "fixture round
missing" message.  More critically, the test's first guard — the one that is
supposed to confirm script success — would give a false green.

## Why "works on the author's machine" does not catch this

In normal development the fixture directory exists, so the guard never fires.
The defense is only exercised in the environment where it is needed (missing
fixture, e.g. a clean clone that didn't receive the new fixture commit, or a
future refactor that renames a fixture round), and that is precisely when it
routes incorrectly.

## Suggested fix

Set `RC` to a non-zero value before returning early so callers see a failure
signal regardless of which variable they check:

```bash
_run_fan_in_on_fixture() {
  local src="$1"
  if [[ ! -d "$src" ]]; then
    echo "fixture round missing: $src" >&2
    RC=99
    return 99
  fi
  ...
  RC=0
  bash scripts/verifier-fan-in.sh "$dest" ... || RC=$?
}
```

Alternatively, make the tests themselves check the helper's return code:

```bash
_run_fan_in_on_fixture tests/fixtures/change-type-enum/round-all-canonical \
  || { echo "helper failed (fixture missing?)"; return 1; }
```

Either approach makes the precondition defense self-consistent: a missing
fixture propagates a clear failure signal through every code path the caller
inspects.
