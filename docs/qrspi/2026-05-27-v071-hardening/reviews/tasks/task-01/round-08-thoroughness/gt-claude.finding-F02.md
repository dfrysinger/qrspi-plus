---
finding: F02
reviewer: gt-claude
round: 8
task: 1
severity: low
change_type: clarity
file: docs/qrspi/2026-05-27-v071-hardening/plan.md
lines: 84-97
persistence_note: orchestrator-persisted (reviewer chat-only fallback; see issue #216)
---

# F02 — plan.md Task 1 spec block stale (12-bullet pre-amendment version)

plan.md `## Task Specs → Task 1` carries the pre-amendment 12-bullet test expectations and older description prose. Has not been updated to reflect R4/R5 amendments that:
1. Expanded Description (NUL carve-out, api_key_env identifier validation, `${!var}` indirect expansion replacing `eval`)
2. Extended Test Expectations 12 → 14 bullets

Canonical task-01.md in worktree IS current. Phase 1 Acceptance Criteria (G1 criterion 5) is correct. Only the per-task spec duplicate in plan.md is stale.

**Required fix**: sync plan.md Task 1 spec block to current task-01.md (14 bullets, amended description).
