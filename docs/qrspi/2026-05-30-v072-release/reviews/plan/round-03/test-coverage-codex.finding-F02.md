---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 20 → Test expectations
referenced_files: [plan.md]
---

# F02 — Task 20 does not explicitly verify Task-11 provenance contract survives the rename flow

Task 20 depends on Task 11, but Task 20 Test Expectations focus on rename/migration mechanics and generic manifest/spec-line behavior; they do not explicitly assert that the full Task-11 provenance contract remains intact after `run-codex-review.sh` → `dispatch-agent.sh` cutover.  
Specifically, there is no expectation that exercises post-rename dispatch and validates required `dispatch_spec` contract continuity (including failure behavior if provenance fields are absent/malformed), so dependency order is declared but not verifiably exercised by tests.
