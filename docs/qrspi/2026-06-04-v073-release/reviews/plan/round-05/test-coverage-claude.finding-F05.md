---
finding_id: R5-F05
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1131-L1143
artifact: plan
round: 5
reviewer: test-coverage-claude
---

T25 (`validate-stage-commit-parents.sh`) Test Expectations — zero-task-wave edge case for `--capture` unspecified.

T25 includes edge-case coverage for a single-task wave ("Single-task fixture wave — integration-base parent counted correctly in expected set; passes when present, halts when absent"). However, the test expectations do not address the zero-task-wave boundary condition: what should `--capture` do when the wave contains no tasks?

**Why this is a testable boundary condition:** The task description says `--capture` writes "the per-task-tip SHAs (`git rev-parse refs/heads/<task-NN>` for each task in the wave)" — the phrase "for each task in the wave" implies the list could be empty. A zero-task wave is the lower bound of the "task-tip set" collection the script operates on. The behavior is ambiguous:
- Option A: write a sidecar with `integration_base:` set and `task_tips:` as an empty list → `--validate` would later accept a merge commit with only one parent (the integration base). Is this a valid stage commit shape?
- Option B: exit non-zero with a named diagnostic (zero-task wave is logically invalid for a stage commit).

Neither direction is specified in the test expectations, so the test writer must guess. If option A is chosen and the implementation is later fixed to option B (or vice versa), there is no test to catch the regression.

**Fix:** Add one test expectation bullet addressing the zero-task-wave case: either "a wave with zero task branches causes `--capture` to exit non-zero with a `wave-empty:` named diagnostic" or "a wave with zero task branches writes a sidecar with an empty `task_tips:` list and exits 0; `--validate` then accepts a merge commit with integration-base as its sole parent."
