---
finding_id: F02
reviewer_tag: silent-failure-codex
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:408-412
artifact: tests/unit/test-change-type-partition.bats
---

# Pipeline with `|| true` + empty-check can pass on scan errors

Materialized from chat-only response by gpt-5.3-codex.

```bash
hits=$(grep -rEn ... | grep -vE ... || true)
[[ -z "$hits" ]]
```

Same pattern as F01: this expects empty output, but `|| true` collapses genuine grep failures into an empty string that satisfies the assertion. The duplication audit can incorrectly pass when the search itself failed.

Suggested fix: distinguish grep no-match (exit 1) from grep error (exit 2+).
