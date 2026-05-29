---
reviewer: code-quality-codex
task: 1
round: 2
finding: F02
severity: low
change_type: scope
status: pending-mostly-defended
model: gpt-5.3-codex
timestamp: 2026-05-28T18:57:00Z
agent_id: t01-r2-cq-codex
persistence_note: OpenAI-family transport returns chat-only; manually persisted. See GH #216.
referenced_files:
  - tests/unit/test-run-third-party-llm.bats
---

## Tests overly coupled to implementation details

**File:** `tests/unit/test-run-third-party-llm.bats`
**Lines:** `324-328`, `338-341`, `407-412`, `656-666`
**Issue:** Tests assert source structure/content (grepping branch labels, documented exit-code comments, extracting function text, banning `grep -P` via source inspection) rather than behavior.

**Orchestrator triage: PARTIALLY DEFENSIBLE; mostly out of scope.**

Per-range analysis:

- **Lines 324-328** (transport-branch-exists test): Pre-existing from commit `272d92f` (T07 Slice 1). Defensible as a documented-API-contract pin (the test asserts the dispatcher's documented branch labels exist in source so downstream callers can rely on them). Out of T1 scope.

- **Lines 338-341** (exit-code-matrix-named test): Pre-existing from `272d92f`. Defensible as a documented-exit-code-contract pin (loops 7 exit codes and asserts each is documented inline). Out of T1 scope.

- **Lines 407-412** (`_extract_ctrl_check_fn` awk helper): T1's work. The helper enables tests 7 and 8 to exercise `_control_char_check` in isolation rather than through the full dispatcher pipeline. Isolation testing of a unit-of-code helper is a legitimate test pattern; the alternative (drive the helper only through the dispatcher) would couple more code per unit-test, slow tests, and make failure attribution harder. Defensible test strategy.

- **Lines 656-666** (`no grep -P` structural assertion): T1's work. **EXPLICITLY REQUIRED by task spec bullet 11:** "The `_control_char_check` helper is implemented without any `grep -P` invocation (structural code-pattern assertion)." The test-writer is doing exactly what the task spec demanded. Removing this would violate the spec. The structural pin exists because `grep -P` silently no-ops on macOS system grep (the root cause of the regression being fixed) — a behavioral test alone cannot catch a future regression where someone reintroduces `grep -P` with `2>/dev/null`. Cannot remove.

**Recommended disposition:** acknowledge the maintainability tension in T1 done-report; do not modify tests in apply-fix. If a broader refactor of T07-era structural tests is desired, file a separate ticket.
