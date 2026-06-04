---
finding_id: R1-F02
reviewer_tag: code-quality-claude
round: 1
task: 02
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-verifier-fan-in-script.bats
---

## F02 — `$stderr` is empty unless `run --separate-stderr`

Lines 232 and 253: `$stderr` conditions are dead code under standard BATS `run` (combined into `$output`). Tests pass because `$output` already contains stderr content. Misleads readers and would break neighboring tests if --separate-stderr is added later.

Fix: drop `$stderr` conditions OR use `run --separate-stderr`.
