# F01 — Unvalidated file-extracted content used as `grep -qE` pattern (ReDoS / bypass)

**Severity:** medium
**Category:** Input validation / Regex DoS + logic bypass
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:307-310,323-327`

The extracted strings are assigned to `REGEX_ADVERB` / `REGEX_NOUN` and used verbatim as ERE patterns with `grep -qE`. Count + uniqueness checks ensure 4 identical occurrences but do not constrain pattern content.

**Attack scenarios:**
- (A) ReDoS: a contributor lands four identical catastrophic-backtracking patterns in `tests/unit/test-using-qrspi-vocab.bats` (e.g., `silently[ab]+(([a-z]+)+x)`); count + uniqueness pass; CI runner exhausts CPU when `grep -qE` runs against the probe strings.
- (B) Trivial-pass: a pattern such as `silently[.*]+(.*)` matches the extraction regex and renders the negative-case test vacuous.

**Recommended fix:** Hard-pin the expected regex shape (prefix + length bound, or an exact equality assertion against a known-good literal) before passing the extracted value to `grep -qE`.
