---
finding_id: R4-F01
reviewer_tag: tc-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:53
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2043
---

# tc-codex R4 F01: Missing test for "must not be patched" prohibition

Spec L53 requires SKILL prose to forbid both (a) override-keeping dropped findings AND (b) patching dropped findings as part of apply-fix work. AC4 only tests (a) via `MUST NOT.*(override|keep)`. No test asserts the "must not be patched" clause.

Disposition: ACCEPT-WITH-ISSUES, file backlog PI-V072-T10-011 (1-line grep addition to AC4 in v0.7.2.x or v0.7.3).
