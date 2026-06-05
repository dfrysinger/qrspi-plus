---
finding_id: F02
severity: medium
category: test-coverage
files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F02 — Acceptance test C-3 exercises a different regex than the deployed unit-test pin

## What the spec requires

`tasks/task-44.md` Scope (line 27) and DoD (line 41):

> Add release-level coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` proving the hardened vocab pins are in the phase acceptance path and **the semantic negative cases trip the pin**.

The phrase "trip the pin" refers to the actual deployed pin in `tests/unit/test-using-qrspi-vocab.bats`. The acceptance test's job is to demonstrate that the regex *as actually deployed* rejects the named negative cases.

## What the implementation does

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` C-3 (lines 42–65 of the diff) defines its own regex variables locally:

```bash
local REGEX_ADVERB='silently[[:space:]]+(fall|degrad|substitut)'
local REGEX_NOUN='(^|[[:space:]])silent[[:space:]]+fallback'
```

then asserts those local regex variables match the three synthetic strings.

But `REGEX_ADVERB` here includes `|substitut` — which is *not* in the deployed unit-test pin (which is `silently[[:space:]]+(fall|degrad)`, see F01). So C-3 demonstrates that *a regex including substitut* catches `silently substitutes the bundled default`, but the regex actually deployed in the unit-test pin does not include `substitut` and would not catch that string.

C-3's name is "anti-pattern regex trips on semantic equivalent phrasings", but it is not actually exercising the deployed regex — it's exercising a hypothetical broader one.

## Why this matters

Two consequences:

1. **C-3 does not provide the coverage the spec asks for** — it does not prove the deployed pin trips on the three named anti-pattern strings. It only proves a broader hypothetical regex would.

2. **C-3 will not detect drift** — if a future fix to the unit pin further narrows the deployed regex (or changes its alternation), C-3 will continue to pass because it doesn't read the deployed regex. The acceptance test should fail loudly when the deployed pin no longer covers the stated semantic family.

## Recommendation

Either:

- (a) Source the actually-deployed regex from the unit-test file (e.g., `grep -oE 'silently\[\[:space:\]\]\+\([^)]+\)' "$PINS/test-using-qrspi-vocab.bats"`) and apply *that* regex to the synthetic strings — so C-3's assertions track whatever the unit pin actually deploys; or

- (b) Construct synthetic H4 bodies that contain each named anti-pattern phrase, write them into temp files, run `_extract_h4` + the unit pin assertions against them, and assert the pin RED-fails. This is the most spec-faithful interpretation of "the semantic negative cases trip the pin" — it actually trips the pin.

This finding is independent of F01: even if the operator accepts the F01 substitut-omission as a documented gap, C-3 should still test the deployed regex (whatever it ends up being) rather than a separately-defined broader one.
