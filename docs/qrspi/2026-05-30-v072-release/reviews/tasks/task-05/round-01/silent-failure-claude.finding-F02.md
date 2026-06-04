---
finding_id: F02
reviewer_tag: silent-failure-claude
round: 1
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:200-211
  - tests/unit/test-change-type-partition.bats:220
  - tests/unit/test-change-type-partition.bats:255
  - tests/unit/test-change-type-partition.bats:301
artifact: tests/unit/test-change-type-partition.bats
---

# `_run_fan_in_on_fixture` early-return (exit 99) never checked by callers — fixture-setup failures mask behind misleading diagnostics

Materialized from chat-only response by claude-sonnet-4.6.

The helper has an early-return path:
```bash
[[ -d "$src" ]] || { echo "fixture round missing: $src" >&2; return 99; }
```

But callers never check the helper's exit status. After early-return, `$RC` is unset (`""`). In bash arithmetic context `""` coerces to `0`:
- `[[ "$RC" -ne 0 ]]` evaluates false → "expected non-zero exit, got 0" diagnostic — masking the real cause (fixture missing).
- `[[ "$RC" -eq 0 ]]` evaluates true → proceeds to `[[ -f "$KEPT" ]]` where `$KEPT` is unset → "expected kept-findings.txt at " (empty path) — again hiding the real cause.

Also `cp -R "$src" "$dest"` has no error check.

Fix: capture/check helper return code at every call site, AND check `cp` exit:
```bash
_run_fan_in_on_fixture path/... || { echo "fixture setup failed (exit $?)"; return 1; }
```

(Related to cq-claude F03 — same `RC` coercion gap; this finding additionally calls out missing return-code checks at every call site and the `cp -R` no-check.)
