# F02 — C-1 regex-count gate accepts silent loss of up to 4 of 8 assertions

**Severity:** low
**Category:** Missing error path / weak gate (silent regression)
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:279-281`

## What

```bash
regex_count=$(grep -cE '!\s+"\$body"\s+=~\s+.*silent' "$pin_file" || true)
# Require at least 4 regex assertions (one per H4 anti-pattern block).
[ "$regex_count" -ge 4 ]
```

The comment ("one per H4 anti-pattern block") implies a 1:1 mapping —
four H4 blocks, four assertions, hence `>= 4`.

## Silent-failure mechanism

The deployed pin file actually carries **eight** matching assertions —
each of the four H4 anti-pattern `@test` blocks contains both an adverb
regex (`silently[[:space:]]+(fall|degrad|substitut)`) and a noun-phrase
regex (`(^|[[:space:]])silent[[:space:]]+fallback`). Both forms match
the grep pattern `=~ .*silent`.

A regression that silently deletes one of the two regex forms across
all four H4 blocks (e.g. removing every noun-phrase pin while keeping
adverb pins, or vice versa — a plausible "consolidation" edit) reduces
the count from 8 → 4, which still satisfies `-ge 4`. The acceptance
gate would not notice that half the semantic-family coverage vanished,
even though one of the three DoD-required negative cases ("no silent
fallback to a neighboring tier") would no longer be guarded at the unit
level.

The C-2 gate (`run_pin` returns 0) wouldn't catch this either, because
deleting an absent-wording assertion does not turn the pin red — it
simply removes coverage.

## Why it matters here

This is a weaker concern than F01 because C-3 does exercise both
patterns end-to-end. But the C-1 gate is the only gate whose stated
purpose is structural ("at least four such assertions, one per H4
block"), and its threshold is set to half what the file actually
deploys. The silent-half-loss case (4 of 8) is exactly the regression
class C-1 is positioned to catch and currently doesn't.

## Suggested fix direction

Tighten the bound to `-ge 8` (or, more durably, count the two pattern
forms separately and require `>= 4` of each), keeping the diff inside
C-1's existing block.
