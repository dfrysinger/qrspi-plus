---
finding_id: F01
reviewer: silent-failure-codex
round: 7
severity: medium
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
No-file-write checks compute file count via `find ... | wc -l | tr -d ' '` without
`pipefail`. If `find` errors (missing dir/permission), the pipeline can still return
success and produce `0`, masking the failure. Fix: run `find` standalone and assert its
status, or use `set -o pipefail`. (Codex chat-only; orchestrator-persisted.)
