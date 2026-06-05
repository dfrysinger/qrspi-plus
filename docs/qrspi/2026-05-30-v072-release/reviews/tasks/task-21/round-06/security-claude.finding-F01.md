---
finding_id: F01
reviewer: security-claude
severity: low
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:754-760, scripts/dispatch-agent.sh:1324, scripts/dispatch-agent.sh:247-258]
disposition: ACT
---
**Batch dispatch path omits `_validate_job_id`** that single-mode (L1324) calls. Broker returning job ID with shlex-special char (e.g., unmatched `"`) passes companion's lenient L670-673 check (only blocks `/` and `..`), reaches manifest unquoted in `await_cmd`; await-round shlex.split raises ValueError → entry marked failed → finding silently dropped. **Fix:** Add `_validate_job_id "$_job_id"` at L759 before `emit_dispatch_manifest_entry "$_job_id" "pending"`. Also correct misleading comment at L248-250 ("downstream consumers eval-expand" is false; await-round uses shlex+shell=False).
