---
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L426-L444
artifact: plan
round: 5
reviewer: silent-failure-claude
---

T11's description and test expectations define the RED-verification gate's proceed/pause decisions for all four adapter output classifications (`pass`, `assertion-failure`, `infrastructure-failure`, vacuous-RED) and for the case where the adapter itself exits 1 (unrecognized runner output — pauses with a distinguishing diagnostic, does not dispatch the implementer). However, neither the description nor the test expectations specify what the gate does when the `qrspi-test-writer` dispatch itself fails before producing test files.

The silent-failure scenario: if `qrspi-test-writer` exits non-zero (e.g., the dispatch fails, the agent cannot parse `task_definition`, the output directory is unwritable, or the agent produces no test files at all), the gate's description says "after the test-writer returns, the orchestrator runs the freshly-written tests once." If the test-writer returns non-zero and wrote zero tests, the runner will execute against an empty test suite. An empty BATS suite exits 0 with zero failures; `bats-adapter.sh` would then classify that as `pass` with zero assertion failures — which is exactly the vacuous-RED condition (adapter returns `pass` with zero targeted assertion failures). However, the vacuous-RED paused path was designed for the case where tests successfully executed but no assertions covered the targeted behavior, not for the case where no tests were written at all.

The current spec could inadvertently permit a code path where:
1. `qrspi-test-writer` fails silently (non-zero exit, no test files written)
2. The runner executes against an empty test directory and exits 0
3. The adapter classifies it as `pass` with no targeted failures
4. The gate identifies it as vacuous-RED and pauses with a diagnostic

While pausing (rather than proceeding to the implementer) is better than dispatching the implementer on no tests, the diagnostic would be misleading: it would say "vacuous-RED detected, no targeted assertion failures" when the real problem was "test-writer dispatch failed entirely." An operator trying to debug this would look at test content rather than the test-writer exit status.

More critically: if the test-writer exits non-zero but some partial test files were written (e.g., 2 of 5 expected test files), running the adapter against partial files could produce an `assertion-failure` classification that looks like valid RED — causing the gate to proceed to the implementer even though the test suite is incomplete.

**Fix:** Add a test expectation to T11 and a corresponding pin in T13 specifying that when the `qrspi-test-writer` dispatch exits non-zero, the RED-verification gate pauses with a named "test-writer dispatch failed" diagnostic (distinct from both adapter-classification-failure and infrastructure-failure) and does NOT attempt to run tests or invoke the adapter against whatever partial output (if any) the failing test-writer may have written. This closes the silent failure where a test-writer crash is reinterpreted as a vacuous-RED or (worse) a valid RED assertion-failure.
