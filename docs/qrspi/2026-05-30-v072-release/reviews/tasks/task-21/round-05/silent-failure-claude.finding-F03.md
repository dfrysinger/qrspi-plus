---
finding_id: F03
reviewer: silent-failure-claude
severity: medium
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:561-565]
disposition: DEFER-v0.7.3
---
**`_resolve_lib` sourced with `|| true`** — convergent with R5 sf-codex F01 and R3 sf-codex F01 already deferred. Source failure root cause never surfaces; only downstream `[routing] WARN` partially signals effect. **DEFER** — duplicate of standing v0.7.3 deferral.
