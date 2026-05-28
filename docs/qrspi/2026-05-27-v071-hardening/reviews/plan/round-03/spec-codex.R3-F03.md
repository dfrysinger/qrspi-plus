---
finding_id: R3-F03
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: spec-codex
---

Task 8 is feature-bundled without an allowed sizing exception

Task 8 touches 8 files: deletions, script logic removal, skill prose edits, unit/acceptance rewrites, new grep-absence assertions. No sizing exception is present (the prior one was removed because "mechanism retirement" is not in the closed set).

Closed exception set allows only schema migration / CI scaffolding / reusable primitives.

Concrete split proposal:
- Task 8A: mechanical deletions (4 cache artifacts + acceptance run_pin/SPIKE removals) + file-absence assertions
- Task 8B: runtime removal of cache-control branch from scripts/run-third-party-llm.sh + unit truth-table removal
- Task 8C: docs/prose cleanup in skills/using-qrspi/SKILL.md + structural absence assertions

Dependency: 8A -> 8B -> 8C (or 8B/8C parallel if test surfaces isolated).
