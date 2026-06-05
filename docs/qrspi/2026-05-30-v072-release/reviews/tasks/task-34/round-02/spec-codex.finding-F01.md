---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: spec-codex
---

Test coverage does not assert the required diagnostics exactly.

Spec (tasks/task-34.md:55-56, 46, 50-58): requires exact mismatch/missing-header diagnostics to be covered by tests ("emits exactly: …").

Observed: new tests check anchor substrings only, not full-string equality.
- tests/unit/test-plan-post-approval-split.bats:429-442 (split into phrases)
- :911-942 (mismatch — 3 substrings)
- :944-965 (missing-header — 3 substrings)
- :1147-1176, :1183-1203 (quick-fix parity — partial)

Diagnostic text can drift (extra/missing text, punctuation/order changes) and still pass. Does not satisfy "emits exactly: …".

Fix: assert entire expected diagnostic string (exact literal match) for both mismatch and missing-header cases including quick-fix parity, instead of substring-only checks.
