# F01 — `grep -cE` counts lines, not occurrences (semantic gap with extraction)

**Severity:** low
**Category:** Reliability / self-consistency
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:308,310`

The extraction uses `grep -oE | sort -u` (occurrence-space). The count uses `grep -cE` (line-space). They agree today because each `=~` pin lives on its own line, but the semantics diverge silently if two occurrences ever land on the same line.

**Recommendation:** Use `grep -oE ... | wc -l | tr -d ' '` for the count so both expressions live in the same occurrence-space.
