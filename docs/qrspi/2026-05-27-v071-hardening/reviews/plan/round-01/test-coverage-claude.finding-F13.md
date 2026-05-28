# Finding F13: G6 integration test scenario from design.md not covered — dispatch success end-to-end

**Artifact:** plan.md
**Task:** Task 7 (G6 part 2 — per-host dispatch transport prose in using-qrspi SKILL)
**Category:** Missing Scenarios from Design
**Severity:** advisory

## Problem

`design.md`'s Test Strategy for G6 specifies three test layers:

1. Unit test for host-detection function with mocked environment signals ✓ (Task 6)
2. Unit test for Codex availability check per host ✓ (Task 6)
3. **Integration test that dispatching a Codex review via the host-appropriate transport succeeds** ✗ (not covered)

Task 7's acceptance test expectations cover transport-branch *selection* — they verify that the correct transport branch is chosen based on the host signal. But "transport selection" is not the same as "dispatch succeeds." The design's integration test scenario requires that the end-to-end dispatch actually completes without error, not just that the right branch is taken.

The Phase 1 Acceptance Criteria include: "Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts using the host-appropriate transport." This is a phase-level gate, but it does not trace to a task-level test expectation in either Task 6 or Task 7. There is no task whose test expectations would produce an integration test that verifies a dispatch completes successfully, even in a mocked or stubbed form.

Without this test, the CI gate for G6 only proves that the correct branch is entered; it does not prove the branch's dispatch logic produces a successful result.

## Recommendation

Add one test expectation to Task 7:

- "The acceptance test includes an integration assertion that, under a mocked dispatch environment (e.g., stubbed `task` tool invocation for Copilot CLI, stubbed `scripts/run-codex-review.sh` for Claude Code), a Codex review dispatch initiated via the host-appropriate transport path completes with exit code 0 and produces output indicating a review was dispatched."

If a full integration test is impractical for this task, note explicitly that the integration test coverage is deferred to the Phase 1 manual smoke (phasing.md replan-gate criterion 3) and that no automated integration test exists for dispatch success — so the gap is acknowledged, not hidden.
