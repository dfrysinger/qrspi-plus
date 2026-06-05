---
finding_id: R5-CQ-CLAUDE-F01
reviewer: code-quality-claude
severity: low
change_type: style
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
at_cap: false
escalate: false
---

# F01 — ID hygiene: `R5` in new test section-header comment

**Introduced by R5 (FIX-F strips "T11" from existing headers but new
section header uses "R5").**

## Location

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — new section
header added in the R5 diff:

```
# ---------------------------------------------------------------------------
# R5 security and correctness fixes (FIX-A through FIX-E)
# ---------------------------------------------------------------------------
```

## Defect

`R5` is a QRSPI-internal round identifier.  Per the ID-hygiene rule,
`G/R/D/T/Q`-prefixed numeric tokens are forbidden in code comments,
test names, `describe`/`it` blocks, and fixture names outside
`docs/qrspi/`, regardless of how the comment is scoped.

FIX-F correctly stripped existing `T11` prefixes from the AC section
headers immediately above this block.  The new FIX-A–FIX-E section
header was added in the same commit but uses "R5" as its identifier.
`cq-codex F01` (already filed in this round) covers the per-test `Fnn`
finding references in the new test comments; this finding covers the
section-level `R5` token which is at a different location and was not
included in that finding's location list.

## Recommended fix

Replace the round-scoped label with a descriptive one:

```diff
-# R5 security and correctness fixes (FIX-A through FIX-E)
+# Security and correctness fix regression-pins (mktemp/mv-f, trap split, subshell emit)
```
