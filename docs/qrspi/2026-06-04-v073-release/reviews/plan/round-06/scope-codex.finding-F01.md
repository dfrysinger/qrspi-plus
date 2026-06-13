---
finding_id: R6-F01
severity: high
change_type: scope
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L35-L36
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L48-L49
artifact: plan
round: 6
reviewer: scope-codex
---

Plan OWNS requires explicit dependencies and forbids forward dependencies. This plan still encodes forward edges (e.g., T11 depends on later task T39; T20a depends on later task T25), which violates the Plan dependency-shape rule. Fix by reordering task IDs or splitting prerequisites so every dependency points only to already-defined earlier tasks.
