---
reviewer_tag: spec-claude
round: 5
status: clean
---

# Spec Review — Task 19, Round 5: CLEAN

## Verdict

All four test-coverage gaps identified in round-04 are addressed correctly, non-vacuously, and traced to the task-19.md DoD. No production code changed. No scope creep. No QRSPI-internal IDs leaked.

## Gap-by-gap confirmation

### Gap 1 — Strengthened unknown-vendor-override test
**File:** `tests/unit/test-second-reviewer-available.bats` (around the `"unknown vendor override"` test)

- Added `wc -l == 1` single-line assertion ✓ (diff line 70)
- Added `grep -q 'host='` assertion ✓ (diff line 72)
- Traces to DoD L42: "Unknown host, missing default vendor, unknown vendor, and unavailable vendor all exit non-zero with exactly one stderr line … naming the detected host plus requested/default vendor."
- Non-vacuous: the single-line count and `host=` grep are load-bearing behavioral contracts, not tautologies.

### Gap 2 — New explicit `none` vendor argument test
**File:** `tests/unit/test-second-reviewer-available.bats` (new `"explicit 'none' vendor argument"` test, worktree lines 322–348)

- `COPILOT_CLI=1`, passes literal `none` as vendor override ✓
- Checks exit non-zero ✓
- Checks exactly one stderr line ✓
- Checks `[second-reviewer-unavailable]` prefix ✓
- Checks `host=copilot-cli` and `vendor=none` ✓
- Production guard clause confirmed present in `second-reviewer-available.sh` line 55: `[ "$_vendor" = "none" ]` — test is non-vacuous, previously untested path.
- Traces to DoD L42 (unavailable-vendor guard) and test expectation at L52.

### Gap 3 — Strengthened empty-default-vendor-guard test
**File:** `tests/unit/test-second-reviewer-available.bats` (around worktree line 535–537, diff lines 116–119)

- Added `grep -q 'host='` and `grep -q 'vendor='` naming assertions ✓
- Traces to DoD L42 naming contract: "naming the detected host plus requested/default vendor."
- Non-vacuous: the naming assertions enforce the diagnostic format contract for this path.

### Gap 4 — New `resolve_second_reviewer_vendor` SUCCESS path execution test
**File:** `tests/unit/test-routing-matrix-application.bats` (new test, worktree lines 643–666)

- Calls `resolve_second_reviewer_vendor 'claude-code' 'anthropic-claude'` (distinct vendors → success path) ✓
- Asserts exit 0 ✓
- Asserts exactly one stdout line ✓
- Asserts `^openai-codex$` on stdout (matrix-driven lookup, not hardcoded) ✓
- Traces to DoD L47: routing-matrix coverage demonstrates same-tier primary + second-reviewer dispatch; and DoD L58: test-routing-matrix-application.bats proves same-tier coverage.
- Non-vacuous: exercises a previously untested function exit path with concrete behavioral assertions.

## Production-code immutability check

The round-05.diff touches only:
- `tests/unit/test-routing-matrix-application.bats` (additive: one new test)
- `tests/unit/test-second-reviewer-available.bats` (additive: one new test + two strengthened tests)

`scripts/second-reviewer-available.sh` and `scripts/_resolve-lib.sh` are untouched. ✓

## QRSPI-internal ID check

No `G27`, `T19`, `F0x`, round-NN, or other QRSPI review-workflow identifiers appear in test names or assertion strings. ✓

## Scope check

No extra tests, helpers, configuration options, or commentary beyond what the four gaps required. ✓
