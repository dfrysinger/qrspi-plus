# F01 — C-3 acceptance test silently passes when 3 of 4 unit-pin sites drift

**Severity:** medium
**Category:** Silent fallback / log-and-continue (test gate)
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:305-306`

## What

The new `[Phase1 G24 negative-case C-3]` test extracts the deployed regex
patterns from `tests/unit/test-using-qrspi-vocab.bats` with:

```bash
REGEX_ADVERB=$(grep -oE 'silently\[.*\]\+\(.*\)' "$pin_file" | head -1)
REGEX_NOUN=$(grep -oE '\(.*\)silent\[.*\]\+fallback' "$pin_file" | head -1)
```

The block comment immediately above (lines 294–296) states the intent
explicitly:

> Extracts the DEPLOYED regex patterns directly from
> test-using-qrspi-vocab.bats so future drift in the unit-pin pattern is
> immediately visible here rather than silently diverging.

## Silent-failure mechanism

The unit-pin file carries **four** copies of each regex — one per H4
anti-pattern `@test` block (lines 145, 180, 213, 252 for the adverb form;
lines 148, 183, 216, 255 for the noun form). `head -1` discards three of
the four matches per pattern.

If a future maintainer (e.g. resolving another constraint conflict like
the one this round resolved at line 252) softens the regex in **one to
three** of the four sites — say, dropping the `substitut` branch from
the `validators:` and `trusted_path:` blocks but leaving it in the
`model_routing:` block (which `head -1` finds first) — the acceptance
test silently continues to pass against the first occurrence's strict
regex while the actual deployed contract has weakened on the other three
H4 surfaces. The acceptance gate then provides false assurance: it
claims the deployed pin matches `silently substitutes the bundled
default`, when in fact only one of the four pins still does.

This is precisely the "silently diverging" failure the comment promises
to prevent. The test's stated invariant ("the DEPLOYED regex patterns")
is plural, but the implementation reduces it to a single sample.

## Why it matters here

Task 44's whole point is hardening pins against rephrasing drift across
the four H4 surfaces. A divergence-detector that only inspects one of
those four surfaces inverts the task's intent: the acceptance gate is
weakest exactly where the unit pins are most prone to per-site edits
(witness the round-2 SKILL.md edit at H4 #4 only, while the regex
extension landed at all four).

Note also that this is not a hypothetical: the round-1→round-2 history
on this very file shows that one H4 body (the missing-block H4) carried
a unique constraint forcing per-site reasoning. The next such conflict
could land asymmetrically and `head -1` would hide it.

## Suggested fix direction

Either (a) require all four occurrences agree before extraction —
e.g. assert `$(grep -cE … | sort -u | wc -l)` is 1 and the extracted
literal count is 4 — or (b) loop the assertions over every match
rather than `head -1`. Both keep the diff inside the C-3 block and add
no helper, so they stay within Task 44's scoped-out surface.
