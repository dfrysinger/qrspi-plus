---
finding_id: R1-F03
reviewer_tag: spec-claude
round: 1
task: 34
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F03 — Malformed-header test does not assert file preservation after halt

Spec DoD line 43 and test expectation line 57 both require "does not rewrite the existing file" for the malformed-header case. The malformed-header test (lines 753-772) does not capture file mtime/content before halt and assert preservation after.

Fix: add `mtime`/SHA assertion before+after halt for malformed-header case.
