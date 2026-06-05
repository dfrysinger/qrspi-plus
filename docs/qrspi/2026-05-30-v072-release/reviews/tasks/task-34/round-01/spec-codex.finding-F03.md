---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F03 — "Single block-hash line" requirement is not actually asserted

Spec requires exactly one `# block-hash: <sha256-hex>` header line per task-34.md lines 38, 50.

Implemented tests (lines 521-533, 793-799): use `grep -E "^# block-hash: ...$"` (presence check), not uniqueness/count check.

Result: files with multiple valid block-hash lines would still pass.
