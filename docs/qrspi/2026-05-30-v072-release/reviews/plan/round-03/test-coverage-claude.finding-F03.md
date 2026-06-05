---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T40
severity: high
change_type: correctness
---

# F03 — T40 body-assertion-guard lint: no negative-fixture RED test pinning the lint actually fails on a seed violation (G21 or BW02)

## What

T40 (G21 bats short-circuit hardening, with G26 BW02 absorbed) creates
`tests/lint/test-bats-body-assertion-guard.bats` carrying both:

- The G21 rule: every `[[ "$body" ... ]]` assertion must have an earlier
  `[ -n "$body" ]` guard in the same `@test` block.
- The G26 BW02 rule: detect `run --separate-stderr` (and future BW02
  patterns), reporting the triggering feature plus `file:line`.

T40's Test Expectations are six bullets that:

- Grep `test-using-qrspi-vocab.bats` for the retrofit guards (bullet 1).
- Run the new lint and confirm it accepts existing guarded R5-era pins as
  **positive controls** (bullet 2).
- Review the lint implementation for discovery, exclusion, and diagnostic
  shape (bullet 3).
- Review the BW02 surface for separate @test coverage and `file:line`
  diagnostic (bullet 4).
- Confirm CI wires the lint on the blocking path (bullet 5).
- Run a targeted BATS invocation of the touched files (bullet 6).

**Nothing in this list exercises the lint against a synthetic violation and
asserts the lint exits non-zero with the expected `file:line` diagnostic.**

Bullet 2 is positive-control only (the lint must not falsely flag valid
guarded prose). Bullets 3 and 4 are code-review of the lint source, not
behavioral exercise. The G21 lint could be implemented as `exit 0` (a
no-op) and bullets 2–4 would still pass: the source review confirms the
shape exists, the positive controls pass because nothing fires. The same
hole exists for BW02 — the lint could detect `run --separate-stderr` only
in dead code and bullet 4 would still pass on inspection.

## Why this matters

Phase 1 Acceptance Criterion #5 in plan.md states:

> `tests/lint/test-bats-body-assertion-guard.bats` catches body-less
> assertions on its seed regression

That phase-level criterion requires a seed regression fixture. But the
per-task T40 Test Expectations contain no such fixture. The round-03
dispatch prompt explicitly named the requirement: "verify Test Expectations
cover both G21 (the `$body` guard rule) AND G26 (BW02 minimum-version rule
with `run --separate-stderr` trigger)." Coverage of "the rule" means coverage
that the rule actually fires when violated, not just that the lint file
contains a paragraph mentioning the rule.

Without a RED-fixture expectation, the Test phase generator may write only
positive controls. A regression that silently breaks the lint's failure path
(e.g., a refactor that swaps `return 1` for `return 0` in the rule body)
would not be caught by any T40-level test.

## Recommended fix

Add two explicit T40 test expectations:

- **G21 seed regression:** "The lint test includes (or runs against) a
  fixture bats file containing an unguarded `[[ "$body" != *foo* ]]`
  assertion; the lint fails non-zero and stderr contains a `file:line`
  diagnostic naming the fixture path and the line of the unguarded
  assertion." (If the fixture is checked-in as a `.bats.fixture` to avoid
  contaminating real bats discovery, name the file pattern.)

- **G26/BW02 seed regression:** "The lint test includes (or runs against) a
  fixture bats file containing a `run --separate-stderr` invocation; the
  lint fails non-zero and stderr names both `run --separate-stderr` (the
  triggering feature) and the fixture's `file:line`."

Optionally pair with a "negative-cleanup" assertion that removing the
fixture violation makes the lint exit 0 again, to prove the diagnostic is
not stuck-on.
