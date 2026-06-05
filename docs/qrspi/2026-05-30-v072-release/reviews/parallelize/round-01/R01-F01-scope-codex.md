---
finding_id: R01-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/parallelization.md:L384-L385
artifact: parallelize
round: 1
reviewer: scope-codex
---

`## Operational Notes` includes runtime baseline-test failure handling and `task-00` injection policy. Per Parallelize DEFERS, baseline-test execution and runtime-injected `task-00` are Implement-owned runtime behavior, not Parallelize-owned planning content. Remove this runtime policy from `parallelization.md` (or reduce it to a neutral pointer that Implement owns runtime adjustments) to keep boundaries clean.
