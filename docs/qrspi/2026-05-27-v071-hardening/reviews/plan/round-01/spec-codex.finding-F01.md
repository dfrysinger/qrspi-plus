---
finding_id: F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/phasing.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: spec-codex
---

## Task 8 adds untraced test surface for G7a (convergent with multiple reviewers)

Same as quality-codex F02 / spec-claude F01. Remove `tests/unit/test-cache-mechanism-retired.bats` creation; rely on CI-green per DKR8.
