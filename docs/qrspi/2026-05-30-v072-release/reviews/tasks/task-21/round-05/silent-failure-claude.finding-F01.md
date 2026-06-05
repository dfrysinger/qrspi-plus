---
finding_id: F01
reviewer: silent-failure-claude
severity: high
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:695-699]
disposition: DEFER-v0.7.3
---
**Batch `_path` fallback silently defaults to "first-party" with no WARN when routing lib absent.** Asymmetric with `_model` fallback at L690-693 which DOES emit `[routing] WARN`. Result: codex-vendor agents on claude-code host silently emit `MODE=first_party` spec lines; orchestrator waits for DISPATCH_FILE never produced. Pre-existing; not introduced by R4→R5 diff. **DEFER** — out of T21 scope (path-filter exfil hardening). Tracked v0.7.3 routing-resilience.
