---
finding_id: F01
severity: MEDIUM
change_type: maintainability
referenced_files:
  - tests/unit/test-dispatch-agent.bats
disposition: DEFER (v0.7.3)
reviewer_tag: cq-codex
round: 7
---

Test file is now ~1973 lines mixing dispatch-agent.sh and dispatch-companion.sh suites. Recommendation: split companion-focused tests into tests/unit/test-dispatch-companion.bats. Refactor; not blocking for v0.7.2.
