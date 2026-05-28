---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-05-17-v07-release/plan.md:L43-L48", "docs/qrspi/2026-05-17-v07-release/plan.md:L550-L565", "docs/qrspi/2026-05-17-v07-release/design.md:L1039-L1041"]
artifact: plan
round: 1
reviewer: quality-codex
---

Task 17 omits the G17/CI dependency that the approved design makes load-bearing for G18. The design states G18 depends on G17 because the evergreen BATS pin has no automatic place to run without the CI workflow, and Task 17's own description says it runs under the new CI workflow from Task 14. However, the task metadata and top-level dependency list only make T17 depend on T13 and T15. That lets a dependency-based parallelization schedule author the evergreen scan before the CI workflow exists. Add T14 as a dependency for T17 so the task graph matches the G18-on-G17 contract.
