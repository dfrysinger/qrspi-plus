---
finding_id: F03
reviewer: silent-failure-claude
round: 2
task: Task 7
category: SILENT_FALLBACK
severity: medium
---

# F03 — Task 7: Copilot CLI acceptance test verifies success signal only, not transport selection

## Location

Task 7 test expectations — the Copilot CLI path acceptance assertion.

## What the plan says

> With `COPILOT_CLI=1` set, the acceptance test exercises a mocked Codex dispatch via `run-codex-review.sh` and asserts the dispatch returns a recognizable success signal (zero exit + non-empty stdout capture).

## The silent failure

The test verifies that the dispatch surface returns *zero exit and non-empty stdout* when `COPILOT_CLI=1`. It does **not** verify that the **Copilot CLI transport** (native `task` tool with `agent_type: code-review` and `model: gpt-5.3-codex`) was selected rather than the **Claude Code shell-pipeline transport** (the existing `run-codex-review.sh` path).

The assertion passes under two distinct execution paths:

| Scenario | `COPILOT_CLI=1` set | zero exit + non-empty stdout? | Transport actually used |
|---|---|---|---|
| Correct | yes | ✓ | native task tool (correct for Copilot CLI) |
| **Silent wrong** | yes | ✓ | shell pipeline (intended for Claude Code only) |

If the dispatch script fails to branch on `detect_host` output—or if `detect_host` is called incorrectly and produces an unexpected result—the script silently falls through to the Claude Code shell-pipeline path. Because the shell pipeline also succeeds in the test environment mock, the assertion passes. No failure signal reaches the test output.

The whole point of G6 (Task 6 + Task 7) is to select the **correct transport per host**. If the test only checks that *some* transport succeeded, transport-selection logic can be broken at the G6 integration boundary without any test catching it.

## Why this matters at runtime

On a real Copilot CLI host, the native task tool is the only functional Codex dispatch path. If the dispatch script routes to the shell-pipeline transport when `COPILOT_CLI=1`, Codex dispatches will fail in production—but the test said green. This is the canonical silent-fallback shape: the test exercises the wrong code path and still passes.

## Proposed fix

Add a test expectation that distinguishes which transport was selected, separate from whether the dispatch succeeded. One approach: assert that the dispatch surface emits a transport-selection trace line (or a specific log token) to stdout or a test fixture that differs between the two transports. For example:

> With `COPILOT_CLI=1` set, the dispatch surface emits a recognizable Copilot CLI transport annotation (e.g., `transport: copilot-native`) to its trace output or fixture capture, confirming the correct code path was selected, not merely that the dispatch returned zero exit.

Alternatively, the test can assert the opposite:

> With `COPILOT_CLI=1` set, the dispatch surface does NOT invoke the `run-codex-review.sh` shell-pipeline command (verified by a mock or spy that would record invocation).

Either approach distinguishes "correct transport" from "any transport that returns success."
