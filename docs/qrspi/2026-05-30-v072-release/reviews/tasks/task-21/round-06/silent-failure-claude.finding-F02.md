---
finding_id: F02
reviewer: silent-failure-claude
severity: low
change_type: clarity
referenced_files: [scripts/dispatch-companion.sh:640, scripts/dispatch-companion.sh:647]
disposition: ACT
---
**`assert_path_under_repo_root` called before `mkdir -p` for round-dir.** path-guard.sh header documents "use AFTER existence check (so missing files fail with their own clearer diagnostic)". macOS BSD realpath requires path existence; calling assert before mkdir means a non-existent valid in-repo round-dir triggers opaque "cannot canonicalize path" instead of a clearer not-a-directory diagnostic. Currently masked because orchestrator pre-creates. **Fix:** swap order — `mkdir -p "$_jobs_dir"` first, then `assert_path_under_repo_root "launch:--round-dir"` after (combines naturally with F01 canonical-form fix).
