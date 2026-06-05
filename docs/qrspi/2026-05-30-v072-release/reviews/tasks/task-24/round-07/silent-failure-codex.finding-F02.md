---
finding_id: F02
reviewer: silent-failure-codex
round: 7
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Negative assertions use `! ... | grep -q ...`, treating any non-zero grep exit as
success including grep runtime errors (status 2). Capture and assert exit status
explicitly (expect 1 for not-found; fail on 2). (Codex chat-only; orchestrator-persisted.)
