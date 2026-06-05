---
finding_id: R3-F02
reviewer: sf-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F02 — Missing JOB_ID silently accepted, unusable await metadata persisted

**File:** scripts/run-codex-review.sh lines 819-831, 246-264

`_job_id` defaults to empty string. If the dispatcher emits no `JOB_ID=...` line, the code still writes a manifest entry with `status:"pending"`, an empty `job_id`, and an `await_cmd` built from the empty job id (`scripts/run-third-party-llm.sh await `).

The caller observes `_dispatch_exit=0` (success) but the manifest contains await metadata that cannot be acted on. A downstream `await` invocation will fail with an empty-argument error, masking the original dispatch-detection failure.

**Fix:** treat empty `_job_id` post-dispatch as a hard failure — emit a diagnostic naming the dispatcher and exit non-zero before manifest write. Optionally accept a `--allow-empty-job-id` opt-in for synchronous dispatchers that legitimately have no job id, but default to fail-loud.
