---
finding_id: F02
reviewer: test-coverage-codex
round: 7
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Grep regression coverage enforces `## Auto Mode Active` absence only in `agents/` and
explicitly skips `skills/`; task expectation requires rejecting host literals in consumer
skill prose. Add a scoped skills-side assertion or document a narrowed allowlist. (Codex
chat-only; orchestrator-persisted.)
