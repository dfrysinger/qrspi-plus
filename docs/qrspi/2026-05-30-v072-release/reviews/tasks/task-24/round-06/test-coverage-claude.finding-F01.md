---
finding_id: F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Coverage gap: no no-file-write test for the override branch (QRSPI_INTERACTION_MODE=auto|interactive). Copilot CLI / Claude Code / unknown-host branches each have one; override path does not. The Test-Expectations "stdout/stderr-only, no files created" bullet covers all execution paths. ORCHESTRATOR: VALID additive coverage-completeness gap. Cap exhausted — accepted-with-issue, deferred to follow-up.
