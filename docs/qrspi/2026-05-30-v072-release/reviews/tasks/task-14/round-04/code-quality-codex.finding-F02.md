---
reviewer_tag: code-quality-codex
round: 4
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F02 — Pin for `-`-prefix rejection asserts only `"start"` (too loose)

**Location:** tests/integration/test-reference-gate-pause.bats:380-381

The new pin for "rejects patterns starting with -" asserts only the substring `"start"`, which could pass on unrelated rubric wording. Tighten to assert a more specific phrase like `must NOT start with` or `start with .*-` to actually pin the contract.

**Fix:** 1-line regex tightening in the test.
