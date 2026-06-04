---
finding_id: F02
reviewer: code-quality-codex
round: 7
severity: low
change_type: refactor
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Test file is large (~670 lines) and repetitive (many near-identical `run bash -c`
setup blocks); extract helpers for common invocation/assertion patterns. (Codex
chat-only; orchestrator-persisted.)
