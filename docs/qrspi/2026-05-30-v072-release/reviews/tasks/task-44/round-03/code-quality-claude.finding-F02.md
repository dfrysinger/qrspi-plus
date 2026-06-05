# F02 — Redundant `-n` guards after stronger preceding checks

**Severity:** trivial
**Category:** Cleanliness
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:319-320`

The `-n "$REGEX_ADVERB"` and `-n "$REGEX_NOUN"` checks are unreachable-on-empty given the preceding `[ "$adverb_count" -eq 4 ]` and uniqueness assertions. Carry-over from the `head -1` era.

**Recommendation:** Remove or replace with a comment.
