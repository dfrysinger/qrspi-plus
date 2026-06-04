---
finding_id: R2-F04
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
  - skills/plan/post-approval-split-contract.md
reviewer_tag: silent-failure-claude
---

Multi-task pre-fan-out HALT property has no test coverage. Contract (+55): "single Case 3 mismatch anywhere in the set halts the entire fan-out" — critical all-or-nothing safety property.

Every mismatch HALT test uses single-task plan. No multi-task test where one mismatches and others are NOT dispatched. Partial-crash test (+322-366) has 3 tasks but only exercises absent-dispatched path (all present tasks match).

Buggy orchestrator implementing decision rule as "halt only for mismatching task, dispatch others" (plausible eager-fan-out bug) passes every test. Dangerous failure: N-1 sub-subagents dispatched, N-1 task files overwritten, mismatching file "preserved" — opposite of contract intent (matching tasks should also remain untouched (safe-skip) when mismatch halts run).

Fix: add multi-task test with one stale-hash task in 3-task plan; assert ZERO dispatches AND all existing task files left untouched.
