---
finding_id: R4-F01
reviewer_tag: code-quality-claude
round: 4
task: 12
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-round-prepare.bats
---

# F01 — Inverted set-math labels in two new convergence test comments

## Locations

- `tests/unit/test-round-prepare.bats:405–406` (convergence: partial-overlap test)
- `tests/unit/test-round-prepare.bats:382–384` (convergence: full-artifact test)

## Observation

In `decide_narrow` (`scripts/round-prepare.sh:264–265`), for `ROUND_NUM=3`:
- `prev1` → `round-02-scope-set.txt` → `s1` (this is NN-1, the more recent)
- `prev2` → `round-01-scope-set.txt` → `s2` (this is NN-2, the older)

**Partial-overlap test** (lines 400–416) sets up:
```bash
printf 'a\nb\nc\n' > "$TASK_DIR/round-01-scope-set.txt"  # → s2 (NN-2)
printf 'b\nc\nd\n' > "$TASK_DIR/round-02-scope-set.txt"  # → s1 (NN-1)
```
Comment says: `# NN-1 = {a,b,c}; NN-2 = {b,c,d}. Sets share {b,c} but neither is a subset / # of the other (s1\s2 = {a} non-empty)`.
**Actual mapping:** NN-1 = `{b,c,d}`, NN-2 = `{a,b,c}`. `s1\s2 = {b,c,d}\{a,b,c} = {d}`, not `{a}`. The labels and the set-difference element are both wrong (swapped from the correct values).

**Full-artifact test** (lines 380–398) sets up:
```bash
printf '*\n'       > "$TASK_DIR/round-01-scope-set.txt"  # → s2 (NN-2)
printf 'a\nb\nc\n' > "$TASK_DIR/round-02-scope-set.txt"  # → s1 (NN-1)
```
Comment says: `# (s1\s2 = {*} non-empty)`.
**Actual:** `s1 = {a,b,c}`, `s2 = {*}`. `s1\s2 = {a,b,c}`, not `{*}`.

The tests themselves assert the correct outcome (`narrowed is False`) and pass. The code logic is sound. The error is confined to the orientation-comment explanation of the set math.

Note: The adjacent `proper-subset` test (lines 418–441) correctly labels NN-1 = round-02 = `{a,b}` and NN-2 = round-01 = `{a,b,c}`, so it serves as a reliable reference for what the correct labeling looks like.

## Why it matters

These orientation comments are the load-bearing documentation that explains *why* each test's seed values produce broaden-vs-narrow. A future maintainer debugging a regression in `decide_narrow` who reads these comments would form an inverted mental model of the set semantics — exactly when accurate guidance is most needed.

## Suggested remediation (informational — budget exhausted, accepted-with-issues)

Partial-overlap (lines 405–406):
```bash
  # s1 (NN-1) = round-02 = {b,c,d}; s2 (NN-2) = round-01 = {a,b,c}.
  # Sets share {b,c} but neither is a subset of the other (s1\s2 = {d} non-empty),
  # so decide_narrow's diverge-broaden path fires.
```

Full-artifact (lines 382–384):
```bash
  # s1 (NN-1) = round-02 = {a,b,c}; s2 (NN-2) = round-01 = {*}.
  # s1\s2 = {a,b,c} non-empty (none of a,b,c equals the sentinel),
  # so decide_narrow's diverge-broaden path fires.
```
