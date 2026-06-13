---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L36
  - docs/qrspi/2026-06-04-v073-release/plan.md:L68-L69
  - docs/qrspi/2026-06-04-v073-release/plan.md:L89-L94
  - docs/qrspi/2026-06-04-v073-release/plan.md:L901-L911
artifact: plan
round: 6
reviewer: spec-codex
---

T39 internally contradictory: the task table and dependency graph define T39 as creating `scripts/structural-lints/check-bats-id-hygiene-sweep.sh`, and T11 depends on T39 for the script's existence (L68, L89-L94, L36). But the detailed T39 spec says the script is pre-committed out-of-band and T39 only creates a test file (L901-L911, L906). Two incompatible contracts for the same task.

Required revision: make T39 single-source consistent. Either (1) T39 owns script creation (optionally split into T39a script + T39b tests), or (2) T39 is test-only and all table/dependency text saying T39 creates the script is removed (including T11's dependency rationale).
