---
name: integrate-genuine-fixture
---

# Integrate (genuine-integrate fixture)

This fixture file lives under `tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md`.

The skill slug extracted by the slug extractor is `integrate` (the path segment immediately
after `skills/`). U14 lint MUST FAIL for this file because `integrate` matches the exclusion
list.

This fixture locks the intended failure mode: the slug-extraction fix must NOT silently
broaden the exclusion to a no-op. A genuine `skills/integrate/` path still trips the
exclusion regardless of what ancestor directories are named.
