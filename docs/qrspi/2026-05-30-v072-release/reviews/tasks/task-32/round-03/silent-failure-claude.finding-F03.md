# F03 — Placeholder prohibition tests false-positive-capable

**Severity:** medium
**Category:** Test design / silent test pass on regression
**File:** `tests/unit/test-interactive-skill-prompts.bats:111-121`

Tests use `grep -F "TODO"` / `"to be filled"` / `"placeholder"` to assert the prohibition is documented. Each grep exits 0 if the string appears anywhere. The prohibition text itself contains those strings, so an accidental TODO/placeholder in the SKILL.md body passes silently.

**Required fix:** Count occurrences, or grep the prohibition phrase as a whole unit, or add a negated check that the bare tokens do not appear outside the prohibition section.
