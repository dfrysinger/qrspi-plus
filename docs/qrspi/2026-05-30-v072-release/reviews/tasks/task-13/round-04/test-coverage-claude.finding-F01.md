# F01 — No later-round (NN≥2) happy-path test: the deferred anchor-write success path is unverified

**Severity:** medium
**Files:** `tests/unit/test-scope-tagger-dispatch.bats`; `scripts/round-prepare.sh` L186-237

## What's covered

Every successful (`exit 0`) invocation in the [T13] block is **round 1**:
- L592-619 happy-path commit-anchor write → `round 1`, `--base-ref base_sha`
- L621-643 `round-NN.diff` emission → `round 1`

Every **later-round (NN≥2)** [T13] test is a *failure* case:
- exit 12 (L698), missing anchor exit 1 (L719), malformed anchor exit 1 (L741),
  fail-closed (L766), missing scope-set exit 1 (L796), empty scope-set exit 1 (L824).

## The gap

There is **no test where a round NN≥2 invocation reaches `exit 0`**. The DoD (task-13.md
L36) and the script's own Fix-A comment (`scripts/round-prepare.sh` L172-176, L221-237)
make the later-round success path structurally *different* from round 1: the anchor write is
**deferred** until after the Step-10 prior-artifact presence assertions
(L221-237). Round 1 satisfies that branch trivially because Step 10 is a no-op on round 1
(`if [ "$ROUND_NUM" -ge 2 ]`, L186). So the entire "Step 10 passes → then write
`round-NN-commit.txt`" sequence — the exact code path Fix A introduced — is never
exercised end-to-end with a clean later round.

Concretely untested behavior:
- A round-2 invocation with a well-formed prior anchor that **advances** past it should
  exit 0 and write `round-02-commit.txt` with the new SHA + LF. If the deferred-write block
  (L228-237) regressed for NN≥2 (e.g., wrong `ANCHOR_PATH`, or an ordering bug that skipped
  the write after a passing Step 10), **no test would catch it** — the missing-anchor and
  fail-closed tests only assert the *absence* of the file on the failure path.

## Suggested coverage

Add a happy-path round-2 fixture: base + r1 commits, write a valid `round-01-commit.txt`,
advance HEAD to a new r2 commit, invoke round 2, assert `status -eq 0`, assert
`round-02-commit.txt` exists and contains exactly the r2 SHA + single LF (mirror the L612-617
assertions). This pins the deferred-write success path that Fix A specifically reshaped.
