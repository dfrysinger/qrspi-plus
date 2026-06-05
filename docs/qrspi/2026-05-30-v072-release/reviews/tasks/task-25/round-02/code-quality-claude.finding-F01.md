---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-task-25-round01-fixes.bats
reviewer_tag: code-quality-claude
---

Test file `tests/unit/test-task-25-round01-fixes.bats` lines 7 and 61 contain QRSPI goal IDs (G31, G1, G30) in code comments. The fix-pass test file that verifies R1 removal of these IDs from the production rules file re-introduced them in its own comment block.

Fix: drop the `(G31, G1, G30)` parenthetical from line 7 and replace `G31` with `internal goal IDs` in line 61.
