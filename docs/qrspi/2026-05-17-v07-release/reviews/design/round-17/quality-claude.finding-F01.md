---
finding_id: R17-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L317, docs/qrspi/2026-05-17-v07-release/design.md:L1145]
artifact: design
round: 17
reviewer: quality-claude
---

The cross-cutting test strategy section misrepresents the pre-implementer RED-verification gate's pause conditions, omitting the most important one.

The G6 recommendation body (design.md line 317) defines two pause conditions for the gate:
1. No assertion fails on the targeted behavior (vacuous-RED — the suite is silent about the intended change).
2. Any test fails for an infrastructure reason (syntax error, import error, fixture/setup error).

The cross-cutting test strategy summary (design.md line 1145) reads: "Orchestrator pauses at the pre-implementer RED-verification gate if any pre-implementation test passes or fails for a non-task-spec reason (syntax error, import error, fixture setup)."

This is wrong in two ways. First, it drops condition (1) entirely — the vacuous-RED case where no assertion fails on the targeted behavior. This is the most critical condition: a suite that pre-passes on every assertion means the test-writer wrote no meaningful RED tests, which is exactly what the gate exists to catch. Second, the phrase "if any pre-implementation test passes" is ambiguous and does not accurately express the gate's logic — a suite containing pre-passing assertions that cover unchanged behavior is explicitly ALLOWED (per the gate's "pre-passing assertions covering behavior the task does NOT change are explicitly permitted" clause). The gate pauses only on vacuous-RED (zero failing assertions on the targeted change), not on any assertion pre-passing.

A downstream Plan or Implement author reading only the cross-cutting summary would produce a gate implementation that (a) ignores vacuous-RED entirely, and (b) may incorrectly pause whenever any assertion pre-passes, breaking the correctly permitted mixed case.

The G6-specific test cases (design.md lines 344-350) do correctly enumerate both pause cases. The cross-cutting summary needs to match.

Suggested fix: update line 1145 to match the G6 recommendation's two-condition structure, approximately:
"Orchestrator pauses at the pre-implementer RED-verification gate when (i) no assertion fails on the targeted behavior (vacuous-RED), or (ii) any test fails for an infrastructure reason (syntax error, import error, fixture setup). Pre-passing assertions covering behavior the task does NOT change do not trigger the pause."
