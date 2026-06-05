---
finding_id: F02
severity: low
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Coverage gap: the "no placeholder values" output-shape assertion runs only for the COPILOT_CLI branch; Claude / unknown-host / override branches lack an equivalent placeholder assertion. Recommendation: add placeholder-value assertions for the other branches (or a table-driven loop). ORCHESTRATOR: VALID additive coverage-completeness gap (low). Cap exhausted — accepted-with-issue, deferred to follow-up.
