# F02 — Greedy `.*` in extraction pattern can over-capture across sub-expressions

**Severity:** low
**Category:** Input validation / regex over-extraction
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:307,309`

`grep -oE 'silently\[.*\]\+\(.*\)'` greedily matches to the rightmost `)` on a line. If a future pin line carries two `silently[…]+(…)` clauses, the extraction over-captures across them, producing a malformed pattern. Today's single-clause-per-line convention masks the risk.

**Recommended fix:** Use bracket/paren-excluding character classes:
```sh
grep -oE 'silently\[[^]]+\]\+\([^)]+\)' "$pin_file"
grep -oE '\([^)]+\)silent\[[^]]+\]\+fallback' "$pin_file"
```
