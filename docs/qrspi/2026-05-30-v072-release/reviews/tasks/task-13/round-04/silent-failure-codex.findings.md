---
finding_id: R4-codex-sf
reviewer_tag: silent-failure-codex
severity: medium
change_type: correctness
referenced_files: [scripts/round-prepare.sh]
disposition: declined-out-of-scope
---

# sf-codex round-4 findings — OUT OF SCOPE for T13 (T12-owned scaffolding)

## F1 — `git diff` errors swallowed (L378-380)
`git diff ... > "$DIFF_TMP" 2>/dev/null || true` suppresses diff errors; a bad/unresolved ref can yield an empty/incorrect `round-NN.diff` at exit 0.

## F2 — non-git sidecar `mv` unchecked (L363)
`mv "$SIDECAR_TMP" "$SIDECAR"` before `exit 2` is unchecked; sidecar emission can fail silently.

## Disposition: DECLINED — out of scope for T13.
Both lines are in the **canonical diff/ref-selection + sidecar scaffolding owned by T12**, not T13. Confirmed against `round-04.diff` (vs task base d3114e3): T13's only `round-prepare.sh` hunks are `@@ -169,16 +169,11` (anchor-write deferral) and `@@ -223,6 +218,24` (Step 10 prior-artifact assertions). L363 and L378-380 are unchanged by T13. task-13.md § Out of scope: "the canonical round-prepare.sh / await-round.sh helper scaffolding and the general G4 diff/ref-selection behavior — T12 owns." Fixing here would be scope creep into a terminal task's owned behavior.

**Recorded as a DEFERRED backlog item** (round-prepare.sh downstream-emission hardening) for a future T12-scope task — see reviews/tasks/task-13-review.md § Deferred.
