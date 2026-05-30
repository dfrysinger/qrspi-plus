---
reviewer: code-quality-codex
task: 1
round: 2
finding: F01
severity: low
change_type: scope
status: pending-out-of-scope
model: gpt-5.3-codex
timestamp: 2026-05-28T18:57:00Z
agent_id: t01-r2-cq-codex
persistence_note: OpenAI-family transport returns chat-only; manually persisted. See GH #216.
referenced_files:
  - tests/unit/test-run-third-party-llm.bats
---

## ID hygiene violation (QRSPI-internal IDs in test comments)

**File:** `tests/unit/test-run-third-party-llm.bats`
**Lines:** `3` (`T07`), `262` (`T03`, `T33`)
**Issue:** QRSPI-internal tokens appear outside `docs/qrspi/` in test comments.

**Orchestrator triage: OUT OF SCOPE for T1 round.**

`git log -L` traces both line ranges to commit `272d92f` ("qrspi-plus T07: Slice 1 unit pins") which predates T1's RED commit (`85d0b6e`) and GREEN commit (`f38344d`). T1's diff does NOT add, remove, or modify any line in the 1-10 or 260-267 range — the only T1 additions in this file are lines 416+ (the 16 new control-char tests).

Per implement SKILL § Per-Task Reviewer Dispatch convention: findings on pre-existing code that the task did not touch are surfaced to be filed as separate hygiene tickets, not addressed within the touching task's apply-fix loop.

**Recommended disposition:** include in T1 done-report under "Pre-existing issues observed during review (out of scope)"; consider filing follow-up issue or batch hygiene cleanup PR.
