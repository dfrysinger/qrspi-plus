# F01 — Five-field template test pins only 4 of 5 fields ("Solution" missing)

**Severity:** medium
**Category:** Spec test expectation incompletely met
**File:** `tests/unit/test-interactive-skill-prompts.bats` test "design/SKILL.md references the five-field per-goal template fields"

Test 30 greps for Outcome, Why this approach, Dependencies + edge cases, Acceptance — but omits Solution, the second of the 5 fields. Test name claims five-field coverage.

**Required fix:** Add `grep -F "Solution"` line.
