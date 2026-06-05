---
finding_id: R1-F02
reviewer_tag: spec-claude
round: 1
task: 34
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F02 — Block-hash line uniqueness ("exactly one") not asserted

Spec line 38 requires "exactly one `# block-hash:` header line". All tests use presence-only grep (`grep -E "^# block-hash: ..."`). A file with two valid block-hash lines would pass every test.

(Overlaps with codex F03.)

Fix: add a `grep -c` test asserting count==1.
