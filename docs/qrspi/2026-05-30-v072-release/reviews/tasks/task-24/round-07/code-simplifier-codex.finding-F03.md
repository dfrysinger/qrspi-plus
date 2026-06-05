---
finding_id: F03
reviewer: code-simplifier-codex
round: 7
severity: low
change_type: refactor
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Duplicated enum checks and file-count checks; extract `assert_detection_type_allowed`
and `assert_no_files_created` helpers. Advisory. (Codex chat-only; orchestrator-persisted.)
