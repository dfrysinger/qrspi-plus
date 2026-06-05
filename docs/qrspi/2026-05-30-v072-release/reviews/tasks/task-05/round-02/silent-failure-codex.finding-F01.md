---
finding_id: F01
reviewer_tag: silent-failure-codex
round: 2
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:464
artifact: tests/unit/test-change-type-partition.bats
---

# Swallowed grep error can still silently pass duplication test

Materialized from chat-only response by gpt-5.3-codex.

One `|| true` site survived the R1 fix-cycle at line 464:

```bash
hits=$(printf '%s\n' "$hits" | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):' || true)
```

Silent-failure impact: a grep runtime error (exit 2+) is masked and produces empty `$hits`. The subsequent `[[ -z "$hits" ]]` check would report success even if filtering failed, hiding real duplicate-enum hits.

Fix: apply the same `rc` pattern used elsewhere:
```bash
rc=0; hits=$(printf '%s\n' "$hits" | grep -vE '...') || rc=$?; [[ $rc -le 1 ]] || fail "grep filter failed: rc=$rc"
```
