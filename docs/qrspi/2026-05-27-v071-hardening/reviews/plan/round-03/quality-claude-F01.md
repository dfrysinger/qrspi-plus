---
id: quality-claude-F01
reviewer: quality-claude
round: 3
severity: medium
task: Task 6
status: open
---

# F01 — Task 6: Transport trace-marker emission not pinned at unit level in `test-host-detection.bats`

## Location

`plan.md` § Task 6 — Test expectations block (lines 184–194 of current plan)

## Finding

Task 6's description adds a behavioral guarantee: "Each dispatch-transport selection path emits a one-line trace marker to stderr at dispatch time: `[transport: shell-pipeline]` when the Claude Code shell-pipeline path is selected, and `[transport: task-tool]` when the Copilot CLI native task-tool path is selected."

Task 6's test expectations, however, contain no assertion that these markers are emitted. The ten bullets in Task 6's test expectations cover `detect_host` output values, `detect_host` exit codes (partially), `check_codex_available` return codes, the mismatch-diagnostic path, and the "no-stderr under normal operation" invariant — but none pins:

- When the Claude Code dispatch path is selected, stderr contains `[transport: shell-pipeline]` exactly once.
- When the Copilot CLI dispatch path is selected, stderr contains `[transport: task-tool]` exactly once.

The markers are tested only at the E2E acceptance level in Task 7 ("the acceptance test asserts the dispatch surface emits the `[transport: task-tool]` marker to stderr exactly once"). This means:

1. A defect such as a misspelled marker (`[transport:task-tool]` without the space, or `[transport: native]`) passes all Task 6 unit tests and only fails at Task 7's mocked acceptance test.
2. The RED-verification gate for Task 6's test-writer produces no failing test for the trace-marker behavior; the test-writer has no specification to work from in `test-host-detection.bats`.
3. If Task 7 is dispatched concurrently or after a partial Task 6 merge, the marker gap has no earlier catch point.

## Required Fix

Add two test expectation bullets to Task 6, covering the transport marker emission:

- When the dispatch surface selects the Claude Code shell-pipeline path (detected host = `claude-code`), `[transport: shell-pipeline]` appears exactly once in stderr and `[transport: task-tool]` is absent.
- When the dispatch surface selects the Copilot CLI task-tool path (detected host = `copilot-cli`), `[transport: task-tool]` appears exactly once in stderr and `[transport: shell-pipeline]` is absent.

These belong in `tests/unit/test-host-detection.bats` alongside the other dispatch-surface assertions, not only in the acceptance test.
