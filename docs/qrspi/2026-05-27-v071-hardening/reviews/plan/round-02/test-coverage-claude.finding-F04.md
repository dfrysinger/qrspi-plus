---
finding_id: F04
round: 2
reviewer: test-coverage-claude
severity: low
task: Task 7
category: behavioral_coverage
status: open
---

# F04 — Task 7: Acceptance test verifies success signal but not transport selection

## Problem

Task 7's acceptance test expectations (items 5 and 6) describe both host-path
assertions as: "the dispatch returns a recognizable success signal (zero exit + non-empty
stdout capture)." The RED/GREEN bifurcation expectations (items 8 and 9) verify that
the outcome differs when the `COPILOT_CLI` signal changes, but they do not specify what
the assertion is that produces the RED state.

**The gap:** A buggy implementation that routes ALL dispatches through the Claude Code
shell pipeline (ignoring `COPILOT_CLI`) and mocks the pipeline to succeed under both
environmental conditions would:

- Return zero exit + non-empty stdout in both cases ✓ (items 5 and 6 both pass)
- Be unable to produce a RED state when `COPILOT_CLI=1` is absent for item 8, unless
  the test is checking something beyond exit code + stdout content

If items 8 and 9's RED/GREEN property is only derivable from items 5 and 6's "zero exit
+ non-empty stdout" criterion, the bifurcation tests provide no additional coverage over
the success-signal tests. The transport-routing decision itself — "task tool under Copilot
CLI; shell pipeline under Claude Code" — would be unverified.

## Why This Matters

The purpose of Task 7 is to update the using-qrspi SKILL so that operators use the
**correct transport per host**. The acceptance test exists to pin that routing decision.
If the acceptance test can pass while the wrong transport is used, the routing change is
unverifiable end-to-end.

The design's G6 test strategy calls out: "integration test that dispatching a Codex
review via the **host-appropriate transport** succeeds." The current expectation text
only verifies "dispatching … succeeds," not "via the host-appropriate transport."

## Required Fix

Add one test expectation per host path that names a distinguishing observable between
the two transports. One practical approach:

> Under `COPILOT_CLI=1`, the acceptance test verifies that the dispatch invocation does
> NOT call `scripts/run-codex-review.sh` as a subprocess (i.e., the shell-pipeline
> transport is not selected); and under `COPILOT_CLI` unset, verifies that the task-tool
> transport path is NOT taken (e.g., no `agent_type: code-review` stub is invoked)

Alternatively, if the mocked dispatch stubs emit distinguishable output per transport,
the expectation can name the transport-specific output token:

> Under `COPILOT_CLI=1`, the acceptance test asserts that the stdout from the mocked
> dispatch contains a transport-specific marker emitted only by the Copilot CLI
> task-tool path (e.g., the string `copilot-transport-ok`), and fails (RED) when
> `COPILOT_CLI=1` is absent because the shell-pipeline path emits a different marker

The exact mechanism is Test-writer–owned; the plan needs to name the observable
property, not just the exit-code outcome.
