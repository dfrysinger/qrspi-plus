---
finding_id: F03
reviewer: code-quality-claude
severity: low
change_type: clarity
referenced_files: [scripts/dispatch-companion.sh:552]
disposition: ACT
---
**Unreachable `""` arm in case-guard.** Empty `_job_tag` already exits at L541 `[ -z ]` check; `""` arm at L552 never fires. Remove (or add comment naming subsumption).
