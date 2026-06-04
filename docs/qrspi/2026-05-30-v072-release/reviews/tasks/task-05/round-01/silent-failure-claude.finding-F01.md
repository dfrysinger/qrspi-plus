---
finding_id: F01
reviewer_tag: silent-failure-claude
round: 1
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:271-274
artifact: tests/unit/test-change-type-partition.bats
---

# Loop variable `$ct` is never used — per-value coverage assertion is a no-op

Materialized from chat-only response by claude-sonnet-4.6.

```bash
for ct in style clarity correctness scope intent; do
  grep -qE "canonical-claude\.finding-F0[0-9]+\.md$" "$KEPT" \
    || { echo "kept-findings.txt missing finding files"; cat "$KEPT"; return 1; }
done
```

`$ct` is declared but never referenced. Every iteration runs the SAME grep. Once the first iteration passes, the rest trivially pass. The loop does NOT verify that each canonical value's finding was kept.

Silent-failure scenario: if `verifier-fan-in.sh` silently drops findings whose `change_type` is `style|clarity|correctness` (e.g., a threshold bug that only passes `scope|intent`), `kept-findings.txt` would still contain `scope` and `intent` finding paths, every loop iteration would match, and the loop would pass with no error.

The `seen=` block below partially compensates, but the loop overstates what it checks. Fix: remove the loop, or rewrite the body to be per-value.

(Convergent with cq-claude F02 and cq-codex F02.)
