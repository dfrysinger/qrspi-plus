---
finding_id: F03
reviewer_tag: silent-failure-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:355-362
artifact: tests/unit/test-change-type-partition.bats
---

# `dup_alt` grep checks only 2 of 120 possible enum orderings — other permutations bypass guard silently

Materialized from chat-only response by claude-sonnet-4.6.

```bash
dup_alt=$(grep -nE 'style\|clarity\|correctness\|scope\|intent|intent\|scope\|correctness\|clarity\|style' "$script" || true)
```

The comment says "in any order," but the grep only matches 2 specific orderings out of 5! = 120. The other 118 orderings pass silently.

Scenario: an implementer writes `[[ "$ct" =~ ^(correctness|style|intent|clarity|scope)$ ]]` — a duplicated 5-value alternation in a different order — and the test passes.

Same issue exists in test 6's grep (line 408) — same character-class formulation, same gap.

Fix: detect any inline alternation naming ≥3 of the 5 canonical values:
```bash
dup_alt=$(grep -nE '(style|clarity|correctness|scope|intent).*\|.*(style|clarity|correctness|scope|intent).*\|.*(style|clarity|correctness|scope|intent)' "$script" \
          | grep -vn "^${def_lineno}:" || true)
```

(Convergent with cq-codex F01 — same "any-permutation underpowered regex" claim, same affected line range.)
