---
finding_id: F01
reviewer: goal-traceability-claude
round: 1
severity: moderate
artifact: plan.md
section: "Task 7 — Test Expectations; Phase 1 Acceptance Criteria"
goal_ids: [G6]
---

# F01 — G6 integration test for dispatch success absent from task test expectations

## Summary

Design's test strategy for G6 specifies an **integration test that dispatching a Codex review via the host-appropriate transport succeeds**. No such test expectation appears in any task's `## Test Expectations` block. Tasks 6 and 7 only test *transport selection*; the Phase 1 acceptance criterion asserts "dispatches succeed end-to-end" but as an observable outcome, not an automated test. The automated integration test the design committed to is missing from the plan.

## Evidence

**Design test strategy (design.md, G6 section):**

> **G6 (cross-CLI Codex detection):** Unit test for the new host-detection function with mocked environment signals. Unit test for the Codex availability check per detected host. **Integration test that dispatching a Codex review via the host-appropriate transport succeeds.**

The design names three explicit test types: two unit tests and one integration test. The integration test is characterized by verifying that an actual dispatch **succeeds**, not merely that the correct transport is selected.

**Task 6 test expectations (plan.md):** Cover only `detect_host()` and `check_codex_available()` unit behavior — correct stdout values, exit codes, stderr silence, bash-3.2 portability. No dispatch success expectation.

**Task 7 test expectations (plan.md):** The acceptance test additions are described as:
- "The acceptance test assertion for the Copilot CLI path passes when `COPILOT_CLI=1` is set and fails (RED) when it is absent"
- "The acceptance test assertion for the Claude Code path passes when `COPILOT_CLI` is unset and fails (RED) when the Copilot CLI signal is active"

These are transport **selection** assertions — they verify which transport annotation is chosen, not that a Codex review dispatch runs to completion.

**structure.md Slice 6 acceptance test row confirms:**

> `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` | Modify | Add end-to-end host-detection coverage **asserting that under each detected host the appropriate dispatch transport… is selected** | G6

"Is selected" — same gap confirmed at the structure level.

**Phase 1 acceptance criterion (plan.md):**

> Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts using the host-appropriate transport. (G6 — replan-gate criterion 3)

This criterion asserts dispatch success but is expressed as a phase-level observable outcome, not as an automated BATS assertion. No task's test expectations provide the automated integration test the design promised.

## Why this matters

The design explicitly committed to an integration test as part of the G6 test strategy. Omitting it means:
1. The plan has no automated gate for end-to-end dispatch success — only for transport selection.
2. The Phase 1 acceptance criterion for "dispatches succeed" will have to be verified manually at phase boundary, which is inconsistent with the otherwise automated test suite in this release.
3. A regression in actual dispatch execution (e.g., transport wiring calling wrong function, shell-pipeline invocation broken by Task 8 edits) would not be caught by BATS and would fall through to the phase-boundary manual check.

## Recommended fix

Add a test expectation to **Task 7**'s `## Test Expectations` block covering actual dispatch success for at least one transport path. For example:

- When invoked with the Copilot CLI host signal active, the dispatch script exits 0 and produces the expected output file or stdout record confirming a dispatch was attempted
- When invoked with the Claude Code default, the shell-pipeline transport exits 0 on a mocked `run-codex-review.sh` stub

Alternatively, if a live dispatch integration test is impractical in BATS, add an explicit note to the task description acknowledging the design test strategy deviation and describing the manual verification procedure used to satisfy the Phase 1 acceptance criterion.

## Traceability matrix row affected

| Goal | Plan-authored Acceptance Criterion | Covering Tasks | Coverage |
|------|------------------------------------|----------------|----------|
| G6 — Cross-CLI Codex auto-detection | Phase 1 criterion 3 (observable); Task 6 unit: host detection + availability; Task 7 acceptance: transport selection | Tasks 6, 7 | **Partial** — design promised integration test for dispatch success; plan only has transport-selection assertions |
