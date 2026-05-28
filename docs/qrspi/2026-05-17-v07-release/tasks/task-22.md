---
task: 22
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G14]
dependencies: [T13]
loc_estimate: 120
---

# Task 22: Migrate three existing BATS files to the shared skill-markdown helper

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-skill-md-content-patterns.bats` (Modify) — replace inline section-extraction logic with `load 'helpers/skill-markdown'` and call the helper's `extract_section` / `extract_and_grep` / `assert_section_contains` functions in place of the hand-rolled awk + grep blocks.
  - `tests/unit/test-cross-skill-contracts.bats` (Modify) — same helper-load refactor; replace the inline section-scoped extraction with the helper API.
  - `tests/unit/test-worktree-aware-defaults.bats` (Modify) — same helper-load refactor; route section extraction through the helper.
- **Dependencies:** T13
- **LOC estimate:** ~120
- **Description:** Migrates the three existing BATS files that independently hand-rolled the section-extract + grep pattern (per the G14 finding) so they consume the shared `tests/helpers/skill-markdown.bash` helper authored in T13. Each file is rewritten to `load 'helpers/skill-markdown'` near the top of the file and to call `extract_section`, `extract_and_grep`, or the BATS-shaped `assert_section_contains` wrapper in place of the previous inline awk + grep blocks; the `require_repo_root` guard replaces any bespoke `REPO_ROOT` resolution. The migration preserves every existing test behavior — every previously-asserted contract (every `@test` block, every assertion target, every failure mode the file is meant to catch) remains intact and continues to fire on the same conditions. No tests are deleted, renamed, or weakened; the change is a helper-load refactor that consolidates the duplicated section-extraction implementation behind the shared helper API while keeping the observable test surface unchanged. Empty-extract, missing-anchor, and end-of-file boundary handling now come from the helper's loud-failure diagnostics rather than each file's locally-implemented guard.
- **Test expectations:**
  - `tests/unit/test-skill-md-content-patterns.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - `tests/unit/test-cross-skill-contracts.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - `tests/unit/test-worktree-aware-defaults.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - Every `@test` block present in each file before migration is present after migration with the same `@test` name and the same asserted contract; no test block is deleted or renamed.
  - The full BATS run for all three files passes against the current skill markdown surface, matching the green pre-migration baseline.
  - When the helper is forced into a missing-anchor or empty-extract path against a fixture, the loud diagnostic from the helper (file, heading anchor, miss reason) is what surfaces in BATS output, rather than a locally-implemented guard message.
  - Each migrated file's `REPO_ROOT` resolution comes from the helper's `require_repo_root` rather than file-local resolution code.
