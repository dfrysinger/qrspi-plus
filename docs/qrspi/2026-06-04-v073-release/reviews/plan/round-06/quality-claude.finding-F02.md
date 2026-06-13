---
finding_id: R6-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1277-L1279
artifact: plan
round: 6
reviewer: quality-claude
---

T31's `dependent_tests:` lists `tests/lint/test-skill-trim-audit.bats` — does not exist; it's the deliverable of T38. Sweep Task Contract requires paths to exist at review time.

Fix: replace with `none` + `grep -rn -- '<pattern>' tests/` proof demonstrating no existing test asserts on the boilerplate content the six new snippet files introduce.

