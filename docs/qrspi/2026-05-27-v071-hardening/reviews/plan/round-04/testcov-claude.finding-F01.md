---
finding_id: R4-F01
severity: medium
change_type: missing
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

# Task 6 — Transport-marker test expectations reference an unnamed "dispatch surface" function

## Location

Task 6 test expectations, plan.md, the two transport-marker bullets:

> "When the dispatch surface selects the Claude Code shell-pipeline path (detected host = `claude-code`), `[transport: shell-pipeline]` appears exactly once in stderr and `[transport: task-tool]` is absent (asserted in `tests/unit/test-host-detection.bats`)"

> "When the dispatch surface selects the Copilot CLI task-tool path (detected host = `copilot-cli`), `[transport: task-tool]` appears exactly once in stderr and `[transport: shell-pipeline]` is absent (asserted in `tests/unit/test-host-detection.bats`)"

## Problem

The test expectations pin the transport-marker behavior to `tests/unit/test-host-detection.bats` but never name the callable entry-point that triggers the transport selection path. The two named functions — `detect_host` and `check_codex_available` — do not emit transport markers (the last bullet in Task 6 explicitly states "neither function writes to stderr under normal operation"). The transport markers are emitted by a third, unnamed code unit called "the dispatch surface."

A test writer sourcing `scripts/run-codex-review.sh` into `test-host-detection.bats` has no anchor for which function to call in order to:
1. Trigger the transport-selection logic
2. Observe `[transport: shell-pipeline]` or `[transport: task-tool]` on stderr

Without a named entry-point, the test writer must reverse-engineer the script structure to find the dispatch function, making the test non-deterministically derivable from the expectations alone.

## Why This Matters

Design DKR10 and the structure.md section for `tests/unit/test-host-detection.bats` state the file "pins transport-selection correctness for both Claude Code and Copilot CLI paths," confirming this test *must* exercise the dispatch path. But the plan's test expectations don't name what code path that is.

## Fix

Add one bullet naming the function (or code path) in `scripts/run-codex-review.sh` that performs transport selection and emits the markers. For example:

> "The transport-marker assertions in `test-host-detection.bats` call `<function-name>` (the dispatch-selection function in `scripts/run-codex-review.sh`) under mocked env signals; they do not call `detect_host` or `check_codex_available` directly."

Replace `<function-name>` with the actual function name once settled. If the dispatch surface is an inline code block rather than a named function, the plan should state that and describe the BATS harness pattern (e.g., sourcing and calling a wrapper).
