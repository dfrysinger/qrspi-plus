---
verifier_status: passed
score: 60
actual_model: unknown
defect_class: missing-acceptance-coverage
---

Cite Check: design.md L410-415 are the G6 Acceptance bullets. Verified they describe validation-helper behavior only (correct/missing/extra parents, single-task wave). The capture step — wave-dispatch resolving task tips via `git rev-parse`, writing to `<artifact-dir>/.wave-state/wave-N-expected-parents.json`, and crucially NOT writing back to parallelization.md — is described in the procedure (L396) and dependencies (L404) but has no acceptance bullet asserting fixture-level proof of those behaviors.

The "NOT written back to parallelization.md" claim is load-bearing for the symbolic-branch-map invariant from research Q11/Q12, and currently has zero acceptance coverage. A reviewer asking "what proves the capture step preserves the invariant?" finds nothing testable in the acceptance section.

The finding correctly distinguishes design-owned acceptance shape (fixture proves X) from plan-owned test code, staying at the right altitude. The fix is small (one bullet) and targets a real gap. Not a critical issue — the invariant is stated in prose — but acceptance shape is the contract Plan implements against, and the capture half of G6 is currently uncontracted.

Moderately confident real issue, modest practical importance.
