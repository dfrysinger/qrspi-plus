---
finding_id: R8-F01
score: 0.83
severity: medium
change_type: scope
referenced_files: [scripts/dispatch-agent.sh, tests/unit/test-dispatch-agent.bats]
status: deferred-v0.7.3
---
Marker-injection guard expansion (FORBIDDEN_MARKERS array covering scope-hint
and artifact markers) plus dedicated tests is broader than task-21's stated
DoD (repo-boundary path hardening + companion audit/allowlist). The guard
is a genuine security fix (closed sec-claude R7 F02 marker-injection breakout),
but spec-codex correctly flags it as out-of-scope per the original task spec.

DEFERRED v0.7.3: amend task-21 spec retroactively to include marker-injection
scope, OR carry forward as a v0.7.3 task-21-amendment line item. Same disposition
as spec-codex R7 F01/F02 (path-guard.sh target-files / scope amendments).
