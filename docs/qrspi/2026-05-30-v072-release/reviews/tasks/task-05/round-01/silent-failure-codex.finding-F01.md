---
finding_id: F01
reviewer_tag: silent-failure-codex
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:360-362
artifact: tests/unit/test-change-type-partition.bats
---

# `grep ... || true` can silently mask real grep errors

Materialized from chat-only response by gpt-5.3-codex.

```bash
dup_alt=$(grep -nE '...' "$script" || true)
[[ -z "$dup_alt" ]]
```

This test expects "no matches," but `|| true` also hides `grep` runtime errors (I/O/read errors, etc.). If `grep` fails, `dup_alt` can be empty and the test passes as if no duplication existed. The duplication audit is the load-bearing assertion for T05 Test Expectation 4 (single-source enum) — masking real grep errors defeats its purpose.

Suggested fix: distinguish between exit code 1 (no match — acceptable) and exit code 2+ (real error — fail loud). Or use `grep -c` and check the count directly.
