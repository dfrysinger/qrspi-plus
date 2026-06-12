---
artifact: design
reviewer_tag: scope-codex
finding_id: scope-codex-F01
change_type: scope
---

# G6 fixes a concrete runtime sidecar path; that's Structure's call

## Location

design.md G6 Solution step 2 capture procedure (R09 added `<artifact-dir>/.wave-state/wave-N-expected-parents.json` + "lands in the same dispatch-chain script as validation").

## Finding

Design owns the runtime-only invariant (expected parents captured at wave-dispatch resolution time, not written to parallelization.md). The concrete path and script-placement decision is Structure-owned file architecture.

## Expected fix

Keep the invariant; defer concrete path to Structure (e.g., describe as "a runtime sidecar under the artifact-dir's review-state tree, exact path Structure's call").
