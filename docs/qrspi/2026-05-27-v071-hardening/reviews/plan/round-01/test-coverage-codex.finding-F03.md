---
finding_id: F03
severity: medium
change_type: plan_update
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: test-coverage-codex
---

## G6 dispatch-success integration test not specified

Convergent with traceability-claude F01, testcov-claude F13. Design Test Strategy promises integration test that Codex dispatch via host-appropriate transport **succeeds** end-to-end. Task 7 only pins transport-selection. Add explicit success-path expectation (mock the dispatch surface; assert non-zero exit on transport-not-routed and zero exit on successful routing).
