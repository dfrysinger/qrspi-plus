---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: silent-failure-claude
---

Circular HALT-diagnostic behavioral tests. Theme D tests (diff +702-707, +726-730, +754-756) compose the expected diagnostic STRING into a local variable, then grep for sub-phrases WITHIN that same string. No orchestrator/skill/code path is invoked.

Tests pass by construction regardless of whether the orchestrator emits the diagnostic. A buggy orchestrator that swallows HALT silently, emits a different message, or writes status: approved and continues — every Theme D test still passes green. The safety contract's most important property (user is told *why* the split was halted) is untestable as structured.

Affects: mismatch (+702-707), missing-header (+726-730), malformed-header (+754-756).

Fix: invoke the actual orchestrator/skill code path (or a thin shim) and capture its emitted stderr; assert grep against THAT output, not against a test-composed string.
