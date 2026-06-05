---
finding_id: F01
reviewer: code-quality-codex
model: gpt-5.3-codex
round: 7
task: 11
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2785-2855
---

# code-quality-codex — task-11 round-07 — F01 (LOW)

**Inspection-style tests over behavior-level tests.**

R7 adds tests that grep source text/line ordering (`grep -A5`, regex against `trap ...`, anchor-string checks) rather than exercising runtime behavior. These are tightly coupled to implementation details and can fail on harmless refactors (message wording, formatting, trap declaration style) while missing behavioral regressions.

## Recommendation

Replace or supplement these inspection-style checks with behavior-level tests (e.g., induce signal/mktemp failure paths and assert cleanup, exit behavior, and manifest integrity), so tests remain stable under internal refactors.

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.
