---
finding_id: R2-F03
reviewer: silent-failure-claude
task: 29
round: 2
severity: low
change_type: correctness
referenced_files:
  - tests/lint/test-design-altitude-boundary-include.bats
---

# F03 — LOW — `head -n1` line-number lookup masks canonical-position drift via duplicate match

Test 3's adjacency check uses `grep -nF | head -n1 | cut -d: -f1`. Duplicate introducer or directive earlier in the file would silently pass (false pass) or fail incorrectly (false fail). 

**Recommended fix:** add a uniqueness assertion (`grep -cF == 1`) for both introducer and directive before the arithmetic.
