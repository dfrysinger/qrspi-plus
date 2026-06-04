---
finding_id: R2-F02
reviewer_tag: cq-codex
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2007-L2033
---

Cleanup discipline issue: the AC4 test allocates `tmp="$(mktemp -d)"` and has multiple early `return 1` paths before `rm -rf "$tmp"`, so failures leak temp dirs. Add a `trap`-based cleanup (or Bats teardown helper) immediately after allocation to keep failure paths clean.
