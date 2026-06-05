---
finding_id: F01
reviewer: silent-failure-claude
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-companion.sh:681, scripts/dispatch-companion.sh:640, scripts/dispatch-companion.sh:559]
disposition: ACT
---
**Raw `$L_ROUND_DIR` stored in job record (not canonical form).** Launch `assert_path_under_repo_root` canonicalizes via `realpath` relative to launch cwd, validates, but DISCARDS canonical value. Raw (potentially relative) path persisted in record. Await reads the raw value, runs `realpath` relative to its different cwd (`<round_dir>/.dispatch/`) — boundary check still passes (both resolve in-repo) but `_raw_dir` constructed from wrong path. Silent misdirection: raw LLM output written to nested wrong dir; await-round can't find file; finding silently dropped. **Fix:** After launch boundary check passes, canonicalize once and use canonical form in BOTH `_jobs_dir` and `printf 'round_dir=%s\n'` to record.
