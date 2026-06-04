---
finding_id: F01
severity: low
change_type: style
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Advisory: `echo "$output" | grep -q '...'` could use a here-string `grep -q '...' <<< "$output"` to drop the pipe/subshell (same behavior, clearer). Pervasive existing pattern. ORCHESTRATOR: DECLINED — advisory; touches many pre-existing lines on a frozen/all-CLEAN file; non-blocking.
