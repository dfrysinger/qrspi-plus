---
finding_id: F01
reviewer: test-coverage-codex
round: 7
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Placeholder-value regression is only tested on the Copilot branch
(`COPILOT_CLI=1`); Claude/unknown/override branches not checked for placeholder
tokens. Add equivalent placeholder assertions for Claude and override/unknown outputs.
(Codex chat-only; orchestrator-persisted.)
