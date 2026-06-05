---
finding_id: R3-F01
severity: low
change_type: clarity
artifact: code
round: 3
reviewer: code-quality-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1283-L1290
---

# TC9 carries `T8` QRSPI-internal ID token in comment header and test name

ID hygiene violation: the newly added TC9 block includes QRSPI-internal ID token `T8` in both a comment header and test name string (`# T8 / TC9` and `@test "[T8 / TC9] ..."`). Per the rule, `T`-prefixed numeric tokens are forbidden in comments/test-name surfaces outside `docs/qrspi/`.

**Disposition note (orchestrator):** This pattern is file-wide (TC1-TC8 all use `T8 / TC[N]`, and other test blocks use `T7`, `T35`, `T36`, `T42`, etc.). Fixing only TC9 makes the file structurally inconsistent. The file-wide ID-hygiene cleanup is already a v0.7.3 backlog item ("ID-hygiene leak in test files — recurring pattern across multiple tasks"). Deferred to v0.7.3 as part of that consolidated cleanup, not addressed in this fix-cycle.
