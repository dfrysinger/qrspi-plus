---
reviewer_tag: quality-codex
change_type: correctness
severity: high
artifact: plan.md
location: Phase 1 Acceptance Criteria
referenced_files: [plan.md]
---

# F01 — Phase acceptance still requires outcomes from deleted/moot tasks

`Phase 1 Acceptance Criteria` still mandates three outcomes that were removed by the round-02 surgery: "parameterized dispatch-routing assertion callers," "consolidated H4-extraction helper," and "bats-deprecation warnings on test-codex-splitter.bats are gone" (plan.md:25). Those map to the deleted/moot G24-F01/G24-F03/G26 standalone work.

The task specs now explicitly mark those surfaces as moot/non-shipping in v0.7.2: Task 44 excludes G24-F01/F03 as moot (plan.md:2370), and Task 40 excludes broader deprecation sweep beyond BW02 rule delivery (plan.md:2309). This creates a release-gate contradiction where acceptance requires work the task plan no longer performs.

**Suggested fix:** rewrite the Phase 1 criterion to match surviving deliverables (T40 + T44), removing F01/F03 standalone-helper/caller requirements and the obsolete `test-codex-splitter.bats` deprecation requirement unless a task is reintroduced to deliver it.
