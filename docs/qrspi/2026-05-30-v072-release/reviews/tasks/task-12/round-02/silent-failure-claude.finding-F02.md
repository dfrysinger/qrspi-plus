---
finding_id: R2-F02
reviewer_tag: silent-failure-claude
round: 2
task: 12
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-round-prepare.bats
---

## F02 — Partial-overlap convergence test comment inverts NN-1/NN-2 labels and cites wrong difference element

`tests/unit/test-round-prepare.bats` lines 400–416 (partial-overlap test).

Comment says:
```
# NN-1 = {a,b,c}; NN-2 = {b,c,d}. ... s1\s2 = {a} non-empty
```

Actual mapping in `decide_narrow` for round-03 evaluation:
- prev1 = round-02 = NN-1 = **{b,c,d}** (written to `round-02-scope-set.txt`)
- prev2 = round-01 = NN-2 = **{a,b,c}** (written to `round-01-scope-set.txt`)
- `s1\s2 = comm -23 {b,c,d} {a,b,c} = {d}` (not `{a}`)

Test passes because partial overlap broadens in either direction. But it loses value as a directional specification: a future implementer who reverses the subset-check direction (`s2_minus_s1 != empty → broaden`) would still pass this test AND the equal-scope-sets test, while breaking the proper-subset-narrows test — but the misleading comment would mask the original direction during debugging.

**Fix — match comment to current file ordering:**
```bats
# round-02 (NN-1) = {b,c,d}; round-01 (NN-2) = {a,b,c}.
# s1 (NN-1) \ s2 (NN-2) = {d} non-empty → neither is a proper subset → broaden.
```
