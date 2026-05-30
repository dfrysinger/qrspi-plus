---
finding_id: R4-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

# Task 7 — "captured stdout is non-empty" for mocked dispatch paths is underdetermined

## Location

Task 7 test expectations, the two R4-added bullets:

> "For the Copilot CLI path: the mocked task-tool dispatch exits with code 0 and captured stdout is non-empty"

> "For the Claude Code path: the mocked `scripts/run-codex-review.sh` dispatch exits with code 0 and captured stdout is non-empty"

## Problem

"Captured stdout is non-empty" is technically falsifiable (fails if stdout is empty) but is underdetermined: any string — including a single space, an accidental debug print, or a stray newline — satisfies the expectation. The test cannot distinguish between "the mocked dispatch ran correctly and produced its expected output" vs. "something incidentally printed to stdout."

The transport-marker bullets in the same task already specify the *stderr* content precisely ("`[transport: task-tool]` appears exactly once"). The stdout expectations are comparatively underspecified. For acceptance-test generation, the test writer needs to know:

1. What the mock is configured to emit on stdout (what simulates a "successful review output")
2. Whether stdout must match a particular pattern (e.g., contains a specific sentinel, review round ID, or mock-output marker)

## Why This Matters

Without a content constraint, a mock that emits `echo "ok"` satisfies the expectation, as does a mock that accidentally echoes its own command-line arguments. The test does not verify that the mocked dispatch *path* was correctly traversed; it only verifies that stdout was non-empty.

This is especially relevant for the acceptance test in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, where the mock setup is the test author's responsibility. The plan should either specify what the mock emits or describe a minimum output pattern the test should assert.

## Fix

Replace "captured stdout is non-empty" with a content-anchored expectation. Two acceptable forms:

**Option A (mock-output sentinel):**
> "For the Copilot CLI path: the mocked task-tool dispatch exits with code 0 and stdout contains the sentinel string emitted by the test harness's mock stub (e.g., `MOCK-CODEX-DISPATCH-OK`)"

**Option B (minimum pattern):**
> "For the Copilot CLI path: the mocked task-tool dispatch exits with code 0 and stdout contains at least one non-whitespace line (confirming the mock stub executed)"

Either form eliminates the risk of an accidental-print false positive while still being easy to satisfy with a minimal test double.
