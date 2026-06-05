---
finding_id: F01
reviewer_tag: code-quality-codex
round: 2
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-change-type-partition.bats:394
  - tests/unit/test-change-type-partition.bats:458
artifact: tests/unit/test-change-type-partition.bats
---

# Over-broad "any permutation" regex can create false positives (test fragility)

Materialized from chat-only response by gpt-5.3-codex.

The new duplication detector regex:

```bash
(style|clarity|correctness|scope|intent)\| ... (repeated 5 times)
```

does NOT enforce that all five canonical values appear exactly once. It also matches strings like `style|style|style|style|style` (or any 5-token repetition from that set), which are not true duplicates of the canonical enum.

That makes these tests potentially fragile and could fail on unrelated alternations. A stricter check should validate the token set + cardinality (e.g., extract the 5 tokens via capture groups then assert `sort -u | wc -l == 5`).

Counter-context: the prior R1 regex only matched 2/120 permutations — this fix is much better than under-broad, and the false-positive case (5 identical tokens in an alternation) is essentially unreachable in practice.
