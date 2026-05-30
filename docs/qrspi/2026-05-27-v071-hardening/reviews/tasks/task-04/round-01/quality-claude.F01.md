---
finding_id: quality-claude-F01
severity: low
change_type: style
referenced_files:
  - tests/unit/test-parallelize-vocab.bats:185
  - tests/unit/test-parallelize-vocab.bats:195
  - tests/unit/test-parallelize-vocab.bats:202
  - tests/unit/test-parallelize-vocab.bats:217
  - tests/unit/test-parallelize-vocab.bats:245
  - tests/unit/test-parallelize-vocab.bats:289
  - tests/unit/test-parallelize-vocab.bats:302
  - tests/unit/test-parallelize-vocab.bats:333
  - tests/unit/test-parallelize-vocab.bats:366
artifact: task-04
round: 1
reviewer: quality-claude
---

# F01 — ID hygiene: Task-number tokens leaked into test names and comments

The new test block at `tests/unit/test-parallelize-vocab.bats:184-380` (added by this task's diff) introduces the QRSPI-internal `T4` task-number token in multiple surfaces that the ID-hygiene rule treats as strict:

- 7 test-name strings prefixed with `[T4-shape]` (lines 202, 217, 245, 289, 302, 333, 366 — every `@test "..."` declaration in the new block)
- 1 comment-block header: `# T4 (v0.7.1-hardening) — Wave-grouped Branch Map structural pins` (line 185)
- 1 inline comment: `Pre-existing T23 vocabulary and row-completeness assertions above remain untouched per Task 4 TE-8.` (line 195)

Per the reviewer ID-Hygiene § Comments-and-test-surfaces split rule: "QRSPI-internal IDs — G/R/D/T/Q-prefixed numeric tokens: forbidden in code comments, test names, `describe` / `it` blocks, and fixture names — flag every occurrence outside `docs/qrspi/`, regardless of how scoped the comment is."

Pre-existing `[T23-vocab]` labels and the pre-existing `# Task 23 (pin 2 of 2)` comment header exhibit the same pattern but are out of scope for THIS task review (not added by this diff).

**Suggested remediation:** rename the test-name prefix to a descriptive, task-number-free tag (e.g., `[wave-grouping-shape]` or `[branch-map-shape]`) and rewrite the comment-block header to describe the rule being pinned rather than naming the task that introduced it.
