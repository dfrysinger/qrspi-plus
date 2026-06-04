---
finding_id: F02
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Coverage gap: QRSPI_INTERACTION_MODE=interactive override is tested only against the unknown-host context, not against COPILOT_CLI=1 or CLAUDE_PROJECT_DIR (the auto override IS tested on both hosts). The "override verdict+evidence win" expectation is only cross-host-validated for auto. Recommendation: add interactive×COPILOT_CLI and interactive×CLAUDE_PROJECT_DIR tests (VERDICT=interactive, correct PLATFORM, DETECTION_TYPE=user-override-only, no INSTRUCTION). ORCHESTRATOR: VALID additive coverage-completeness gap. Cap exhausted — accepted-with-issue, deferred to follow-up.
