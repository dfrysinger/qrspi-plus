---
finding: F02
reviewer: spec-claude
severity: fail
category: test-coverage
task: 12
round: 1
---

# F02 — Missing convergence table test cases: full-artifact, partial-overlap, and proper-subset-with-safety-margin fixtures absent

## What the spec requires

**Test expectation** bullet 6:
> Exercise convergence fixtures for **missing**, **empty**, **full-artifact**, **superset**, **overlap**, **disjoint**, **equal**, and **proper-subset-with-safety-margin** scope sets, plus the `HEAD~1` mismatch fallback case.

That is nine distinct fixture classes + one fallback.

**Definition of done** bullet 4:
> Convergence handling broadens on missing, empty, full-artifact, superset, overlap, or disjoint scope sets; narrows only for equal sets or proper-subset-with-safety-margin cases; and broadens if the previous commit anchor no longer matches `HEAD~1`.

## What the tests cover

`tests/unit/test-round-prepare.bats` convergence section (lines 269–337) has exactly **four** tests:

| Test | Fixture class |
|---|---|
| "equal scope-sets narrow" (line 269) | equal |
| "superset … broadens" (line 290) | superset |
| "disjoint scope-sets broaden" (line 306) | disjoint |
| "HEAD~1 mismatch falls back to broaden" (line 322) | HEAD~1 mismatch |

## What is missing

Five fixture classes from the spec table have no corresponding test:

1. **missing** scope-sets → broaden (convergence path, not the blocking-error path): when `QRSPI_SCOPE_TAGGER_ENABLED=false` (the default), a missing `round-(NN-1)-scope-set.txt` should cause a broaden decision rather than a blocking error. No test exercises this convergence branch.

2. **empty** scope-sets → broaden (convergence path): same rationale. No test.

3. **full-artifact** → broaden: no test. The design specifies that a scope-set that covers the full artifact (i.e., is functionally equivalent to "no narrowing") must still cause a broaden. No fixture or assertion for this case exists.

4. **overlap / partial-overlap** → broaden: the disjoint test uses completely non-overlapping sets (`a,b` vs `x,y`). The spec also requires a partial-overlap fixture where some entries are shared but the sets are neither equal nor a proper subset in either direction. No such test exists.

5. **proper-subset-with-safety-margin** → narrow: only the equality case (`a,b,c` == `a,b,c`) is tested as a narrow-eligible path. The spec separately names the "proper-subset" case (round NN-1 has a strict subset of round NN-2's tags) as narrow-eligible. No test verifies that `{a,b} ⊂ {a,b,c}` results in `narrowed=True`.

## Impact

The convergence decision is the most safety-critical path in `round-prepare.sh` — an incorrect broaden silently costs reviewer compute; an incorrect narrow silently misses findings. Five of the nine required fixture classes have no test coverage. The implementation's `decide_narrow()` function's `comm -23` subset logic (lines 248–254 of `round-prepare.sh`) is specifically untested for partial-overlap and proper-subset.

## Required fix

Add five tests:
1. Missing scope-sets with `QRSPI_SCOPE_TAGGER_ENABLED=false` → `narrowed=False`.
2. Empty scope-sets with `QRSPI_SCOPE_TAGGER_ENABLED=false` → `narrowed=False`.
3. Full-artifact scope-set (e.g., value equals a sentinel or a list that spans the artifact) → `narrowed=False`.
4. Partial-overlap scope-sets (e.g., `{a,b,c}` vs `{b,c,d}`) → `narrowed=False`.
5. Proper-subset (round NN-1 = `{a,b}`, round NN-2 = `{a,b,c}`) with valid HEAD~1 anchor → `narrowed=True` and `scope_hint` matches round NN-1 set.
