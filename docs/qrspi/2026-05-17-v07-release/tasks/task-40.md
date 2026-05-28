---
task: 40
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G13]
dependencies: []
loc_estimate: 90
---

# Task 40: u14-lint slug-extraction logic update with confusable-prefix and genuine-integrate fixtures

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-u14-lint.bats` (Modify) — replace the current absolute-path substring match (which trips on any path whose ancestor directory happens to contain the exclusion token `integrate`) with a skill-slug extractor that derives the slug from the path segment immediately after `skills/` and compares only that slug against the exclusion list; preserve the intended failure mode so genuine `skills/integrate/` paths still trip the exclusion.
  - `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md` (Create) — confusable-prefix fixture whose path contains `integrate` as a non-skill ancestor segment (e.g. a worktree-like prefix such as `worktrees/feature-integrate-foo/skills/replan/` is the failure-mode this represents; the fixture realizes that shape by placing `skills/goals/SKILL.md` underneath `tests/fixtures/u14-worktree-confusable/`, where `u14-worktree-confusable` contains `integrate` as a non-skill ancestor segment) so the skill-slug resolves to `goals` and u14-lint MUST pass.
  - `tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md` (Create) — genuine-integrate fixture under a real `skills/integrate/` skill-directory boundary so the skill-slug resolves to `integrate` and u14-lint MUST fail, locking the intended failure mode.
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** Removes the u14-lint false positive that fires when BATS runs from a QRSPI integrate worktree (or any path whose ancestor directory happens to contain the substring `integrate`) by replacing the substring scan in `tests/unit/test-u14-lint.bats` with a skill-slug extractor anchored to the `skills/<slug>/` directory boundary, then locks the contract with two fixtures exercised in the same test run. The lint logic update derives the skill slug from the path segment immediately after `skills/` in each candidate path, compares that slug against the exclusion list, and treats a path that is not under `skills/` at all as yielding an empty slug that matches no exclusion — eliminating the worktree-path false positive while preserving the intended failure mode for in-scope files that actually live under an excluded skill slug. The confusable-prefix fixture at `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md` realizes a worktree path containing `integrate` as a NON-skill directory segment: the ancestor directory `u14-worktree-confusable` carries the substring `integrate` while the actual skill slug resolves to `goals`, and u14-lint MUST PASS for this fixture because the slug extractor compares `goals` (not the absolute path) against the exclusion list. The genuine-integrate fixture at `tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md` realizes a genuine integrate-skill path where the slug extractor resolves the slug to `integrate`, and u14-lint MUST FAIL for this fixture so the regression test proves the exclusion still bites on genuine skill-directory matches and that the slug-extraction fix did not silently broaden the exclusion to a no-op. Both fixtures are exercised in the same test run so a single invocation of the BATS file demonstrates the contract end-to-end: false-positive eliminated AND genuine exclusion preserved.
- **Test expectations:**
  - The u14-lint test invocation exercises both fixtures in the same run: the confusable-prefix fixture path resolves to skill slug `goals` and u14-lint passes for that path, while the genuine-integrate fixture path resolves to skill slug `integrate` and u14-lint fails for that path.
  - The slug extractor derives the skill slug from the path segment immediately after `skills/` so a path containing `integrate` as a non-skill ancestor directory segment (e.g. `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md`) resolves to a slug that does NOT match the exclusion list.
  - A path that is not under `skills/` at all yields an empty slug from the extractor and matches no exclusion (boundary case: extraction returns no false-positive match when the `skills/` segment is absent).
  - The intended failure mode is preserved: a file under a genuine `skills/integrate/` directory boundary still trips the exclusion regardless of what its ancestor directories are named.
  - The BATS file loads the two fixture trees from `tests/fixtures/u14-worktree-confusable/` and `tests/fixtures/u14-genuine-integrate/` via repo-relative paths so the test is reproducible from any worktree checkout location and does not depend on the working-directory string.
  - The replaced substring-match logic is removed (not left in as a fallback) so the false-positive cannot regress through a code path that still scans the absolute path for the exclusion token.
