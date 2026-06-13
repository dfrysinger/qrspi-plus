---
finding_id: R4-F01
severity: high
change_type: scope
referenced_files: [/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md]
artifact: plan
round: 4
reviewer: scope-codex
---

The plan drifts across the Plan/Structure/Implement boundary by specifying implementation mechanics (exact command invocations, script-internal control-flow behavior, runtime sidecar handling, SHA-shape validation sequencing, and named diagnostics) as task-level commitments. Under `skills/plan/owns-defers.md`, plan.md should define ordered tasks, dependencies, LOC, and plain-language test expectations, while line-by-line logic/control-flow and operational mechanics are deferred to Implement/Structure. Trim task descriptions to behavior outcomes and move script-level execution/flow details to downstream artifacts.

