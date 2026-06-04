# Silent Failure Hunter — Task 13 (G9), Round 5 — CLEAN

No silent-failure findings within T13-owned lines for the round-05 diff.

## Scope reviewed
Round 5 is the final cap-bend ADDITIVE-ONLY round. The only production change
is a verified zero-behavior dead-code removal in `scripts/round-prepare.sh`
(L192–200); everything else is additive `[T13]` bats tests in
`tests/unit/test-scope-tagger-dispatch.bats`. T12-owned canonical scaffolding
(TASK_BASE_SHA `|| true`, sidecar `mv`, G4 diff/ref swallowing) is explicitly
out of T13 scope and was not re-raised.

## Behavior-equivalence verification of the dead-code removal
Removed: `ANCHOR_CONTENT="$(cat "$PRIOR_ANCHOR_PATH" 2>/dev/null || true)"`
plus the `printf '%s' "$ANCHOR_CONTENT" | python3 …` pipe.

The pre-removal command carried BOTH a stdin-feeding pipe and a
`< "$PRIOR_ANCHOR_PATH"` redirect on the same `python3` call. In POSIX shell
the rightmost stdin source wins: the `< file` redirect superseded the pipe, so
`python3` already read from the file and the `printf` half was dead (output
discarded). Removal is behavior-preserving. The surviving redirect-fed regex
validation still exits 1 loudly on missing/malformed prior anchors; the removed
`2>/dev/null || true` only masked errors on the now-deleted dead `cat`, so no
live error path was newly swallowed.

## New tests
The additive `[T13]` tests all emit explicit failure diagnostics, assert exit
codes 0/1/10/11/12 against fail-loud paths, verify the fail-closed
no-stray-anchor invariant, and clean up `mktemp -d` dirs. The
`grep … && { …; return 1; } || true` constructs are standard assert-absent
patterns, not production error-swallowing.

## Categories checked
- Swallowed errors: none introduced.
- Silent fallbacks: none introduced (validation still fails loud).
- Missing error paths: none introduced.
- Inappropriate error transformation: none.
- Log-and-continue: none.
- Partial state on failure: anchor-write deferral preserves the
  "failed verification leaves no round-NN-commit.txt" invariant; tests pin it.
