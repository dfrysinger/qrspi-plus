---
finding_id: F01
reviewer: security-claude
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-companion.sh:620, scripts/dispatch-companion.sh:626-627, scripts/dispatch-companion.sh:547-566, scripts/dispatch-companion.sh:661]
disposition: ACT
---
**`--round-dir` write-path exfiltration.** Companion launch mode boundary-checks `--prompt-file` (L620) but NOT `--round-dir` (L_ROUND_DIR). Attacker invoking companion with `--round-dir /tmp/exfil --prompt-file <repo-internal>` passes prompt boundary but writes job record to `/tmp/exfil/.dispatch/.jobs/...`; await later writes raw LLM output to `/tmp/exfil/.dispatch/<tag>.raw` — output exfil. **Fix:** add `assert_path_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"` after required-flag check, before `_jobs_dir` construction.
