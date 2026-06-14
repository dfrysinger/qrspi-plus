# Sweep Task Contract

Read this file when authoring a task that removes, replaces, or enforces an invariant across many files at once, or when reviewing such a task.

A **sweep task** removes, replaces, or enforces an invariant across many files at once (e.g., "strip `model:` from all agent frontmatter," "rename `qrspi-foo` to `qrspi-bar` across all skills," "remove all `${VAR}` references in CDs"). It systematically invalidates test files that assert on the swept property's previous values, even when those tests are not in `files_in_scope` — so the per-task gate never runs them, the task ships GREEN, and integrate surfaces stale-test failures.

A sweep-task plan-spec MUST include in its Test Expectations a `dependent_tests:` field with one of two values:

- A **list of test file paths** the per-task gate must additionally run. Each must be a file (not a directory glob) and exist at plan-authoring time. Each listed test SHOULD either (a) pass unchanged once the sweep is applied or (b) require a specific predicted update — one sentence per file.
- The literal string `none` followed on the next line by a grep-confirmable command of shape `grep -rn -- '<pattern>' tests/` returning zero matches. The pattern is the swept identifier (e.g., `'^model:'`); the plan-reviewer re-runs and surfaces any hit.

Skipping `dependent_tests:` on a sweep-shaped task is a plan-spec defect. The Plan reviewer (`agents/qrspi-plan-reviewer.md` § Sweep-task detection) detects sweep-shaped tasks heuristically (>5 same-extension files in `files_in_scope` plus one of eight sweep keywords in title/description, case-insensitive word-boundary) and emits `severity: high, change_type: correctness` when missing or malformed. Worked examples A and B live in `references/worked-examples.md`.
