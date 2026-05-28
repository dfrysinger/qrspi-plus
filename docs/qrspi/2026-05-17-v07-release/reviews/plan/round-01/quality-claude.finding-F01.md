---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L291-L303]
artifact: plan
round: 1
reviewer: quality-claude
---

Task 07's frontmatter declares `loc_estimate: 0`, but the task creates five new BATS test files (`test-run-third-party-llm.bats`, `test-config-model-routing.bats`, `test-citation-density-validator.bats`, `test-routing-matrix-application.bats`, `test-g5-telemetry-emission.bats`). The description covers substantial test coverage for each file — the dispatcher exit-code matrix alone covers seven codes across two transport branches, plus config resolution, key resolution, and cache-control gating. Even under a "test files are unmetered" convention, a zero estimate is not the same as "unmetered" — the LOC plan review check flags tasks >200 LOC without a sizing exception, but a zero LOC estimate for a task that clearly creates code is a wrong value rather than a high value. The correct value for a purely-test task authored under the QRSPI convention is either the actual estimated LOC (likely 200-300 across five files) or an explicit `sizing_exception: reusable primitives` with an "unmetered" note in the description matching the T30 pattern. As written, `loc_estimate: 0` will mislead downstream tooling or readers that use the estimate to budget implementer effort.

Resolution: set `loc_estimate` to a plausible non-zero estimate (e.g. 200) or apply `sizing_exception: reusable primitives` with a description note that test files are unmetered, matching the conventions used in T13, T19, and T30.
