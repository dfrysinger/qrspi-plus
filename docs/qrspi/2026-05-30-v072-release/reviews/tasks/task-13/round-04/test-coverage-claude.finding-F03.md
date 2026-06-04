# F03 — Fail-closed "no stray anchor" invariant is pinned only for the missing-prior-anchor exit; the other deferred-write exits are not

**Severity:** low
**Files:** `tests/unit/test-scope-tagger-dispatch.bats` L766-794; `scripts/round-prepare.sh` L172-237

## What the invariant actually guards

The Fix-A comment (L172-176, L221-227) states the anchor write is deferred so that **any**
Step-10 exit-1 leaves no stray `round-NN-commit.txt`. Step 10 has **four** distinct exit-1
paths that all precede the deferred write:

1. missing prior anchor (L188-191)
2. malformed prior anchor (L194-203)
3. missing scope-set, enabled + NN≥3 (L211-214)
4. empty scope-set, enabled + NN≥3 (L215-218)

## The gap

The dedicated fail-closed regression test (L766-794) only covers **path 1** (missing prior
anchor). The malformed-anchor (L741) and scope-set (L796, L824) failure tests assert the
exit code and diagnostic but **never assert the absence of `round-NN-commit.txt`**. So the
"no stray anchor" invariant — the whole point of the deferral — is verified for only one of
the four exits that depend on it.

A regression that re-ordered the write back before *just one* of the scope-set checks (e.g.,
moved the anchor write between Step 10's anchor block and its scope-set block) would slip
through: path 1 still passes the fail-closed test, but paths 3/4 would silently leave a stray
anchor with no test failing.

## Suggested coverage

Add the `[ ! -e round-NN-commit.txt ]` assertion (mirroring L788-793) to the malformed-anchor,
missing-scope-set, and empty-scope-set tests — or add a parameterized fail-closed sweep over
all four Step-10 exit conditions. Cheap to add; closes the gap between "exit code is right"
and "the side effect that matters is absent."
