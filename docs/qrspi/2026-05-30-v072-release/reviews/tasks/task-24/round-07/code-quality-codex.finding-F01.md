---
finding_id: F01
reviewer: code-quality-codex
round: 7
severity: medium
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
ID hygiene: QRSPI-internal token `[T24]` appears in comments and multiple `@test`
names. Per the review rule, T-prefixed internal IDs are forbidden on test/comment
surfaces outside `docs/qrspi/`. (Codex chat-only; orchestrator-persisted.)
