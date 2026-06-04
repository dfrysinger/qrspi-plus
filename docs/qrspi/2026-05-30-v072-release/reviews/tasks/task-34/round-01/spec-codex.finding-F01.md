---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F01 — Required HALT diagnostics are not behaviorally asserted

Spec requires runtime halt behavior to emit exact/named diagnostics (task file mismatch exact text; missing-header exact text; malformed-header named diagnostic and no rewrite) per task-34.md lines 55-57.

Implemented tests:
- Mismatch test (lines 689-721): checks hash inequality + unchanged file, but does NOT assert emitted diagnostic text.
- Missing-header test (lines 727-747): checks condition + greps contract doc text, but does NOT assert runtime diagnostic emission.
- Malformed-header test (lines 753-772): checks malformed pattern + greps contract doc text, but does NOT assert runtime diagnostic emission (or unchanged file).

Result: test coverage is incomplete versus required behavioral expectations.
