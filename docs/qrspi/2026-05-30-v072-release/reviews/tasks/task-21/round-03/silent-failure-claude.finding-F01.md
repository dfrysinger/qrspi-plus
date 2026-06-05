---
finding_id: F01
reviewer: silent-failure-claude
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:575-579, scripts/dispatch-agent.sh:691]
---
**Batch `--artifact` silently swallows missing-file + bypasses guard.** Combined `[[ -n .. && -f .. ]]` skips both existence diagnostic and boundary guard when file absent. Single mode separates these. Fix: replace with two-step `assert_file_exists` then `assert_path_under_repo_root` (unconditional on existence after `-n` test). Convergent with sec-claude F03 (TOCTOU angle).
