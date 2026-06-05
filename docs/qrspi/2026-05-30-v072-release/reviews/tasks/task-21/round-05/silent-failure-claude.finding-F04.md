---
finding_id: F04
reviewer: silent-failure-claude
severity: low
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:681-683]
disposition: DEFER-v0.7.3
---
**`resolve_tier` stderr suppressed via `2>/dev/null`** — actionable tier-resolution diagnostics permanently discarded. Pre-existing. **DEFER** — minor diagnostic loss, out of T21 spec; tracked v0.7.3.
