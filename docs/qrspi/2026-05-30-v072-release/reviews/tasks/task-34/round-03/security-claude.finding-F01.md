---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
  - skills/plan/post-approval-split-contract.md
reviewer_tag: security-claude
round: 3
task: 34
---

Pre-fs-ops ordering test is doc-audit only; misleading test name creates false assurance of behavioral enforcement.

**Test name:** `[split] Task-ID Validation rejects non-numeric and path-traversal IDs before any filesystem op` (lines 995-1003)

**Actual test body:** greps the contract document for the keywords `"before|prior to|pre-fan-out"` and `"halt|HALT|reject"` in the `## Task-ID Validation` section. Nothing more.

The contract (line 93) states: *"Before any block-hash audit, filesystem probe (`test -e`), per-task path construction, or sub-subagent dispatch, the orchestrator MUST validate…"*. The ordering is the LOAD-BEARING property protecting against path traversal. The test verifies only that the word "before" appears in prose.

**Concrete attack scenario:** Attacker edits plan.md with `### Task ../../../home/user/.ssh/authorized_keys: backdoor`. An orchestrator that places path construction BEFORE the regex check (e.g., to reuse the path in error diagnostics) calls `test -e tasks/task-../../../home/user/.ssh/authorized_keys.md` first → returns false → Case 1 absent → dispatches sub-subagent to write to the out-of-bounds path. The regex test at lines 1005-1023 verifies the regex itself rejects traversal IDs, but NOT the ordering invariant.

**Fix:** Either (a) add a behavioral fixture that simulates the pre-fan-out decision pass receiving a traversal-ID and asserts the regex check fires before any path construction (e.g., spy on `test -e` calls); OR (b) strengthen the doc-audit test to assert the contract text contains BOTH `"before"` AND specifically `"test -e"` or `"filesystem probe"` in the list of operations that must follow validation, AND add a comment noting the behavioral-verification limit so future reviewers know the test is advisory.

**Advisory (not separate finding):** Contract line 95 uses `^[0-9]+$` which accepts task ID `0`. Contract prose says "positive integer" — minor inconsistency, no traversal risk. Consider `^[1-9][0-9]*$`.
