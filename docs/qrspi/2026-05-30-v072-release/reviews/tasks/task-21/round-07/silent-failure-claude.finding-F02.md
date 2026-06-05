---
finding_id: R7-F02
severity: high
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh]
status: closed-cycle-8
---
_validate_job_id hard-exit in batch loop orphaned broker job (broker job already
submitted by dispatch-companion.sh launch; dispatcher exit 1 abandoned remaining
tags and skipped failed-manifest emission). Closed by 514a6cd via inline regex
+ WARN+continue+emit_dispatch_manifest_entry "" "failed".
