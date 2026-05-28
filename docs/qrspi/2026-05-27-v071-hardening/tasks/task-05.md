---
status: approved
task: 5
phase: 1
pipeline: full
goal_ids: [G5]
task_type: code
model: sonnet
---

# Task 5: Remove path-shaped exemption groups from evergreen-lint helper

- **Target files:** `tests/unit/test-evergreen-markdown.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~40
- **Description:** All five path-shaped exemption groups (six `case` patterns total) are deleted from the `_is_path_exempt()` function in `tests/unit/test-evergreen-markdown.bats`. The inline `<!-- evergreen-exempt -->` comment mechanism is retained as the sole remaining escape hatch; none of the five pre-existing violations that already carry inline markers are disturbed. After this change the evergreen scan covers its intended surface unconditionally: no directory tree is silently exempted by path. The carve-out removal is validated by the existing evergreen-lint job in CI, which is the design-stated test surface (Design DKR5).
- **Test expectations:**
  - The evergreen scan executed against all repo-tracked markdown files reports zero violations (the five pre-existing violations all carry `<!-- evergreen-exempt -->` inline markers and are suppressed without relying on path carve-outs)
  - The shell function `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains zero path-shaped `case` pattern branches after the modification; a structural grep assertion in `tests/unit/test-evergreen-markdown.bats` verifies the absence (fails RED on the current codebase with six branches present, passes GREEN after deletion)
  - The five existing `<!-- evergreen-exempt -->` inline markers remain intact in their original locations after the modification
  - No new violations are introduced by the removal of the carve-out groups (verified by running the scan after the edit)
  - The jargon scan (scoped to `skills/**` and `agents/**`) is unaffected and continues to report zero violations
  - The existing evergreen-lint job in CI reports zero violations after carve-out removal
