---
finding_id: F02
reviewer: security-claude
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-companion.sh:537-538, scripts/dispatch-companion.sh:547, scripts/dispatch-companion.sh:552]
disposition: ACT
---
**Await reads `tag`/`round_dir` from job record without re-validation.** Launch enforces `[a-z][a-z0-9_-]*` on L_TAG (L613) but await `_job_tag` (L537) is used at L552 in `_raw_file="$_raw_dir/${_job_tag}.raw"` with no allowlist; `_job_round_dir` (L538) is used at L547 in `_raw_dir` construction with no boundary check. A crafted job record with `tag=../../other-task/security-claude` redirects raw output to a sibling task tree; `round_dir=/tmp/...` exfils outside repo. **Fix:** Re-validate `_job_tag` via case-guard mirroring L_TAG allowlist; call `assert_path_under_repo_root "await:round_dir" "$_job_round_dir"` before `_raw_dir` construction.
