---
finding_id: quality-codex-R2-F01
severity: medium
change_type: yagni
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
artifact: structure
round: 2
reviewer: quality-codex
status: applied
---

The Section Contract for `tests/unit/test-agent-frontmatter-no-model.bats` added a second `@test` block requiring each of 41 agent files to mention an allowed tier name in body prose. design.md scopes G7b verification to structural linting of frontmatter only; tier vocabulary is preserved in dispatcher prose (`skills/using-qrspi/SKILL.md`), not in every agent file.

**Resolution:** removed the over-constraining tier-presence assertion from the Section Contract. The created test now has a single `@test` block matching design.md G7b scope.
