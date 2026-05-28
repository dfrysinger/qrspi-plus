---
finding_id: F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/goals.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: goal-traceability-codex
---

## G6 mismatch-diagnostic only traced as prose presence

Convergent with spec-claude F02, traceability-claude F01, testcov-claude F08, testcov-codex F04.

**Resolution:** Add behavioral expectation (Option A from spec-claude F02): assert one-line stderr emission identifying disagreement when detect_host output differs from codex_reviews config; pin in tests/unit/test-host-detection.bats.
