---
finding_id: F03
reviewer: security-claude
severity: low
change_type: scope
referenced_files: [scripts/dispatch-companion.sh:628, scripts/dispatch-companion.sh:666]
disposition: DEFER-v0.7.3
---
**Non-atomic job record write with predictable filename (TOCTOU symlink pre-placement).** `_job_id` from `$$ + date +%s` is enumerable; `>` redirect follows symlinks. Inconsistent with mktemp+mv pattern in dispatch-agent.sh:381-383 manifest writer. **DEFER** — internal-mechanism hardening; out of T21 path-boundary spec; tracked v0.7.3 atomic-write convergence.
