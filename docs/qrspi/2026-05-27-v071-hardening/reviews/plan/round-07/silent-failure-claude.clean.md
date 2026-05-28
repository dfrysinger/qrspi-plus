---
status: clean
reviewer: silent-failure-claude
round: 7
artifact: plan.md
---

# Silent Failure review — round 7 — clean

## Verification of R6→R7 change (Task 7 mock-sentinel wording, plan.md lines 224-225)

My R6 finding flagged the R5 wording — "captured stdout provides evidence that the dispatch invoked the mock transport rather than falling back to a different code path" — as unfalsifiable. The defect was that "evidence" was undefined, and a dispatcher that emitted the `[transport: task-tool]` / `[transport: shell-pipeline]` stderr markers (lines 219-220) before mock invocation would satisfy any reasonable interpretation of "evidence" even if execution fell back to a non-mock path between the routing decision and the transport call.

The R7 wording closes the loophole. Lines 224-225 now require captured stdout to contain "a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back." Five properties make this falsifiable:

1. The marker is a **distinguishable string**, not arbitrary "evidence" — no test-writer wiggle room about what counts.
2. The marker is **emitted by the mock transport itself**, not by the dispatch surface — the dispatcher cannot satisfy the assertion by emitting a marker before transport invocation.
3. The marker value is one **the mock produces and no other code path produces** — uniqueness is a stated requirement, so a fallback path cannot accidentally or intentionally emit the same string.
4. The marker is in **captured stdout**, separating it from the dispatcher's own stderr trace markers (lines 219-220) — the two channels independently verify two distinct facts.
5. The clause **"exit code 0 alone is insufficient proof"** is retained, blocking the simplest silent-fallback shape (mock never called, dispatcher returns 0 via a different code path).

Properties (2) and (3) are load-bearing for falsifiability. If only the mock produces the marker, then presence of the marker in stdout is a sufficient proof of mock invocation — a fallback code path cannot satisfy the assertion. The R7 wording is now a proper silent-fallback negative invariant.

Combined with the surrounding expectations on Task 7, the test forms a closed proof against silent dispatch failures:

- **Routing decision proof:** lines 219-220 require the dispatcher's stderr marker for the correct transport to be emitted exactly once and the opposite marker to be absent. This proves the routing branch ran.
- **Mock invocation proof:** lines 224-225 (R7 wording) require the mock-unique marker in stdout. This proves the mock was actually invoked, not bypassed.
- **Non-zero propagation:** line 226 requires the dispatch surface to propagate a non-zero exit from the mocked transport with no suppression and no log-and-continue.
- **Mismatch-path no-suppression:** line 227 requires that the mismatch-warning path (DKR6) also propagates non-zero from the mocked transport — confirmed set-aside S1 covers this surface.

The R6 silent-fallback concern is fully closed. No new silent-failure shapes were introduced by the R6→R7 diff (the diff is scoped to the wording change at lines 224-225 only).

## Confirmed set-asides honored

S1 (DKR6 mismatch warning-only), S2 (Task 6 atomicity), S3 (auth-failure), S4 (codex_reviews absent), and S5 (plan length) were not re-raised this round per instruction.

## Scope-hint discipline

The dispatch prompt narrowed focus to Task 7 mock-sentinel wording. I read the full diff (single-hunk, lines 224-225 only) and found no significant silent-failure shapes outside the hinted surface. No load-bearing signal to broaden the next round's diff ref.

## Conclusion

Clean. The R7 wording is falsifiable, closes the R6 loophole, and the surrounding Task 7 expectations form a closed proof against silent dispatch fallback.
