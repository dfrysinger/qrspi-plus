---
finding_id: F02
reviewer_tag: code-quality-codex
round: 1
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-change-type-partition.bats:270-274
artifact: tests/unit/test-change-type-partition.bats
---

# Canonical-value loop contains a non-varying assertion (dead iteration variable)

Materialized from chat-only response by gpt-5.3-codex.

The loop iterates `ct in style clarity correctness scope intent`, but `ct` is never used inside the loop body. The same grep runs five times identically, which adds noise and implies per-value validation that is not actually happening there.
