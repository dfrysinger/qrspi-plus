---
finding_id: F01
reviewer: silent-failure-codex
severity: medium
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:561-565, scripts/dispatch-agent.sh:696-699]
disposition: DEFER-v0.7.3
---
**`_resolve_lib` sourced with `|| true` swallows load failure.** Resolver functions silently absent → first-party routing fallback. **DEFER** — duplicate of T21 R3 sf-codex F01 already deferred; out of T21 scope (path-filter boundary). Tracked in v0.7.3 issues.
