---
finding_id: F01
reviewer: code-simplifier-codex
round: 7
severity: low
change_type: refactor
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Repeated subprocess setup across nearly every test; add scenario helpers
(run_copilot/run_claude/run_unknown/run_override_auto). Advisory. (Codex chat-only;
orchestrator-persisted.)
