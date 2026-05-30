---
status: clean
reviewer: scope-claude
artifact: plan.md
round: 7
scope: plan-scope (OWNS/DEFERS)
---

# Scope review — clean

R6→R7 diff scope: two edits.

1. **plan.md lines 224–225 — Task 7 mock-sentinel wording (3rd revision).**
   Checked against `skills/plan/owns-defers.md` Plan OWNS ("Test expectations …
   Plain language only; not assertion code, not `expect(...)` strings") and the
   Boundary-drift signals lexical-leakage list. The new wording —
   "captured stdout contains a distinguishable marker string emitted by the
   mock transport (a value the mock produces and no other code path produces),
   proving the dispatch invoked the mock rather than falling back; exit code 0
   alone is insufficient proof" — describes an **observable test condition**
   (a stdout marker uniquely producible only by the mock transport) without
   prescribing test mechanics. Lexical scan: no `expect(`, no `assert.`, no
   `toBe(`, no `assertEqual`, no BATS `run`/`[ ... ]` syntax, no literal
   sentinel string value quoted, no function signatures, no control-flow
   keywords. The parenthetical defines the **uniqueness property** of the
   marker, not its literal value or how the test asserts on it — that
   remains Implement-TDD's negotiation room. R5-F02's concern (the explicit
   "the test asserts against" phrasing) is **not** re-introduced. The
   unfalsifiability gap that R6 reviewers converged on is closed by
   specifying the discriminator (mock-only marker) rather than the
   assertion mechanic. Within Plan OWNS.

2. **structure.md Slice 7 SKILL.md row `cache_control` addition.**
   Outside plan.md surface; not in scope for this review.

Set-asides S1 (DKR6 mismatch warning-only), S2 (Task 6 4-behavior atomicity),
S3 (Auth-failure), S4 (codex_reviews absent), S5 (Plan length) honored —
not raised.

No boundary-drift findings. No scope-compliance gaps (OWNS coverage
unchanged from prior round; only narrowed wording within an existing
test-expectations bullet).
