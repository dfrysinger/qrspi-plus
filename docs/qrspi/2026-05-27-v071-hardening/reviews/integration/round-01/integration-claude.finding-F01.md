---
finding_id: R1-F02
severity: high
change_type: correctness
referenced_files: [agents/qrspi-test-writer.md]
artifact: integration
round: 1
reviewer: integration-claude
---

## qrspi-test-writer.md "All modes" Output Contract contradicts new implement-phase RED-run behavior

**Surface:** `agents/qrspi-test-writer.md:73`, `:75`, `:261`, `:267-272`

T2 (commit-hygiene scope) added implement-phase Behavior steps:
- Line 73: "Run the tests via `bats` to verify RED ... Tests must fail with assertion-failure ..."
- Line 75: "Commit the RED tests ... Use the scratch-file commit pattern ..."

And broadened tool grant to `Read, Write, Edit, Bash, Grep, Glob`.

But the bottom-of-file "## Output Contract" block at lines 267-272 still asserts (all modes):
- "The agent does NOT run any test file it writes. Running tests is out of scope for this agent."
- "The agent does NOT fix production code."

And the test-phase "## Red Flags — STOP" section at line 261 lists "Attempting to run tests or
report results (the orchestrator runs tests)" as a stop-the-presses red flag, with no
visual scoping to test-phase mode (a reader hits it as a global rule).

**Cross-task impact:** test-writer is dispatched in BOTH Implement-phase and Test-phase from
the same prompt body. T2 added implement-phase RED-run+commit but left contradictory test-phase /
all-mode prose intact. An LLM that reads top-to-bottom hits the contradiction at line 271 / 261
and has documented justification to silently skip the RED run — defeating the cross-task
invariant T2 introduced.

**Suggested fix:** rewrite the "All modes" block to scope the "does not run / does not commit"
assertions to test-phase mode explicitly; update Red Flags to qualify "Attempting to run tests"
as test-phase-specific; add cross-reference back to lines 73-75 from the implement-phase
contract section.
