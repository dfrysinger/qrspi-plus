---
finding_id: F04
reviewer_tag: silent-failure-claude
round: 1
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:263
artifact: tests/unit/test-change-type-partition.bats
---

# `grep -c . "$KEPT" || true` swallows grep errors

Materialized from chat-only response by claude-sonnet-4.6.

```bash
kept_count=$(grep -c . "$KEPT" || true)
[[ "$kept_count" -eq 5 ]] || { echo "expected 5 kept findings, got $kept_count"; cat "$KEPT"; return 1; }
```

`grep` exits non-zero both for zero matches (exit 1 — acceptable) AND for errors (exit 2 — fail loud). `|| true` masks both.

Fix: distinguish error (exit ≥2) from no-match (exit 1):
```bash
kept_count=$(grep -c . "$KEPT")
grep_rc=$?
[[ "$grep_rc" -le 1 ]] || { echo "grep failed (exit $grep_rc) reading $KEPT"; return 1; }
```

(Related family with sf-codex F01 + F02 — same `|| true` pattern in different test sites.)
