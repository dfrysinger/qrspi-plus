---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T11's test expectations are entirely documentation-shape assertions — none of them verify runtime behavior of the pre-implementer dispatch flow or the RED-verification gate.

Every one of T11's six test expectations follows the pattern "The [section] in [file] documents [behavior]" or "[Prose] enumerates [items]." These assertions verify that the documentation was written, not that the wired behavior works correctly. The primary happy path for T11 — that a task_type: code task actually triggers a test-writer dispatch followed by a RED-verification gate and then an implementer dispatch — has no behavioral test expectation here.

T13 picks up the behavioral pin (test-red-verification-gate.bats and test-tdd-dispatch-order.bats), but those tests target T08/T11/T12's combined output. T11's own test expectations should include at least one expectation that is observable behavior rather than documentation shape. For example:

- "When the Implement orchestrator processes a task_type: code task, a test-writer dispatch occurs before the implementer dispatch — the per-task dispatch log shows test-writer entry before implementer entry."
- "When the adapter returns infrastructure-failure, the orchestrator halts with a named diagnostic and no implementer dispatch occurs."

The bypass/pause behavior is also not covered in T11's own expectations — only in T13's integration tests. T11's behavioral contract (the pause mechanic, the split-mode awareness) should have at least one behavioral expectation in T11 itself, since T13 is in a different task.

This gap means that if T11's implementation is wrong but the documentation is written correctly, T11 passes its own test expectations while the behavior remains broken until T13 runs.
