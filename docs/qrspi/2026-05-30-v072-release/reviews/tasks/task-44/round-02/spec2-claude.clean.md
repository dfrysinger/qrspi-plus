# Spec Review (round 2, claude) — Task 44: G24-F05 anti-pattern pin regex hardening

**Result:** CLEAN — no findings.

## Summary

Re-review of the R1 spec finding fix. The amended spec (post-R2 F01) permits a minimal one-phrase semantically-equivalent rewrite to `skills/using-qrspi/SKILL.md` to resolve the constraint conflict between the regex's `substitut` branch and the negated-form prose ("does not silently substitute defaults"). The implementer's diff:

1. Replaces that single phrase with "uses no implicit default substitution" — semantically equivalent, removes the false-positive risk that previously forced `substitut` to be omitted from the unit-test regex.
2. Extends all four unit-test pins in `tests/unit/test-using-qrspi-vocab.bats` with `substitut` in the alternation: `silently[[:space:]]+(fall|degrad|substitut)`. The companion noun-phrase regex `(^|[[:space:]])silent[[:space:]]+fallback` is unchanged. Each `[[ ! "$body" =~ ... ]]` is preceded in the same `@test` block by `[ -n "$body" ]`.
3. Strengthens the C-3 acceptance test to extract the DEPLOYED regex literals from the unit-pin file (`grep -oE`), then applies them via `printf | grep -qE` (set -e-honoring on bash 3.2) to the three semantic-equivalent phrasings. Future drift in the unit pattern surfaces here rather than diverging silently.

## Verification

- DoD bullets 1–7: all satisfied (literal pins replaced; body guards present; regex catches all three semantic equivalents; non-regression via green unit run on post-CD1 prose; acceptance test exercises the hardened pins; diff scoped to four pin sites + acceptance + one permitted prose edit; no new helpers).
- Test expectations 1–7: all satisfied.
- Target files: three files modified, all within the amended Target files allowance. No deviation.
- Manually traced the regex extraction in C-3: `grep -oE 'silently\[.*\]\+\(.*\)'` correctly captures `silently[[:space:]]+(fall|degrad|substitut)` from the unit-pin source line via greedy backtracking onto the first `]+(...)` boundary; the captured ERE then matches "silently degrades…" and "silently substitutes…" as required. The NOUN extraction is symmetric.
- Spot-checked SKILL.md H4 body for residual silent-fallback prose that could trip the now-broader unit pin: the remaining sentence "never falls back silently to an agent-bundled default, never substitutes an unannounced model" places "silently" AFTER the verb (not before), so it does not match `silently<space>(fall|degrad|substitut)`. The hyphenated "silent-fallback class" reference uses a hyphen, not whitespace, so it does not match the noun-phrase regex. The unit test should remain green.

No further findings. Gate passes; downstream reviewers may proceed.
