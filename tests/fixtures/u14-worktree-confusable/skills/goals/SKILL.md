---
name: goals-confusable-prefix-fixture
---

# Goals (confusable-prefix fixture)

This fixture file lives under `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md`.

The ancestor directory `u14-worktree-confusable` contains the substring `integrate` as a
non-skill directory segment. The skill slug extracted by the slug extractor is `goals`
(the path segment immediately after `skills/`), NOT `integrate`.

U14 lint MUST PASS for this file because the slug extractor resolves to `goals`, which
does not match the exclusion list. This fixture verifies that the slug-anchored extraction
eliminates the worktree-path false-positive class.
