# F02 — Scope-set gate: only the "enabled + fail" side is tested; the gate-off and gate-pass branches are uncovered

**Severity:** medium
**Files:** `tests/unit/test-scope-tagger-dispatch.bats` L796-853; `scripts/round-prepare.sh` L206-219

## The conditional

```sh
SCOPE_TAGGER_ENABLED="${QRSPI_SCOPE_TAGGER_ENABLED:-false}"
if [ "$ROUND_NUM" -ge 3 ] && [ "$SCOPE_TAGGER_ENABLED" = "true" ]; then
    ... missing scope-set -> exit 1
    ... empty scope-set   -> exit 1
fi
```

This compound gate has two boolean inputs (`ROUND_NUM >= 3`, `ENABLED == true`) plus the
inner missing/empty checks. The [T13] tests exercise **only the all-true-and-fail** corner:

- L796 `QRSPI_SCOPE_TAGGER_ENABLED=true`, round 3, scope-set missing → exit 1 ✓
- L824 `QRSPI_SCOPE_TAGGER_ENABLED=true`, round 3, scope-set empty → exit 1 ✓

## The gap — both "should-not-fire" sides are untested

1. **Gate-off (tagger disabled):** No test proves that with
   `QRSPI_SCOPE_TAGGER_ENABLED=false` (or unset → default `false`, L208) a round-3
   invocation with a **missing** scope-set does **not** exit 1 on the scope-set check.
   If the `&& [ ... = "true" ]` clause were dropped or inverted, the script would start
   failing every disabled-mode round-3 prep, and no test would catch it. The disabled-mode
   fall-through is only asserted as *SKILL.md prose* (L216-221), never against the script.

2. **Gate-eligibility boundary (round 2):** No test proves that round 2 with tagger enabled
   and a missing scope-set is **not** failed by this check (the `>= 3` floor). An off-by-one
   to `>= 2` would silently break round-2 narrowing-ineligible preps.

3. **Gate-pass (enabled + valid non-empty scope-set):** No test feeds a present, non-empty
   `round-02-scope-set.txt` through a round-3 invocation to confirm it passes the gate
   (and proceeds — this is also the only path that would exercise `decide_narrow`'s
   scope-set consumption at L277-313). Only the failing inner branches are pinned.

## Suggested coverage

Add at minimum: (a) round 3, `QRSPI_SCOPE_TAGGER_ENABLED=false`, no scope-set → assert it
does **not** exit 1 on the scope-set check; (b) round 3, enabled, valid non-empty
`round-02-scope-set.txt` present + advancing HEAD → assert exit 0. Together these pin both
sides of the gate boolean instead of just the failing corner.
