---
finding_id: R4-F01
reviewer_tag: gt-codex
severity: medium
change_type: intent
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md:802
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:42
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:54
  - skills/using-qrspi/SKILL.md:995
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2088
---

# gt-codex R4 F01: Trace break — observations score shape diverges from spec

Spec/test/implementation contradiction on observations score shape:
- G28 + task-10 L42/L54: each finding's score
- Implementation: single `representative_score` (Reading B)
- AC5: requires `representative_score`, rejects bare `score:`

Traceability chain is broken between spec and implementation+test.

CONVERGENT with tc-codex R4 F03. Disposition: covered by PI-V072-T10-005 (spec disambiguation in v0.7.3).
