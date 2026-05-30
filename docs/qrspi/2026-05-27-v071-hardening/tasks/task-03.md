---
status: approved
task: 3
phase: 1
pipeline: full
goal_ids: [G3]
task_type: code
model: sonnet
---

# Task 3: Promote fence-aware section extractor to shared test-helper library

- **Target files:** `tests/helpers/skill-markdown.bash` (modify), `tests/unit/test-skill-md-content-patterns.bats` (modify), `tests/unit/test-helpers-skill-markdown.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~110
- **Description:** A new fence-aware section-extraction function (`extract_section_fence_aware`) is added to `tests/helpers/skill-markdown.bash` alongside the existing heading-anchored `extract_section`. The new function correctly handles heading-shaped lines inside code fences; emits a named diagnostic to stderr with a non-zero exit code when extraction is empty (both when the anchor heading is absent and when the anchor is present but no content lines follow); and produces output equivalent to the inline `extract_review_round` helper it replaces. The two call sites of the inline helper migrate to the new shared function and the inline definition is removed. Coverage in `tests/unit/test-helpers-skill-markdown.bats` pins the behavioral contract. Bash-3.2 portable. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - The new `extract_section_fence_aware` function returns content from the anchor line (inclusive) through the last line before the next out-of-fence section boundary
  - A `### ` or `## ` heading line that appears inside an open code fence is not treated as a section boundary and does not terminate the extraction
  - Exiting a code fence (closing triple-backtick line) restores heading-boundary detection for subsequent lines in the same extraction
  - When the target section extends to end-of-file with no subsequent section boundary, the function extracts content from the anchor line through the last line of the file
  - For both error paths, the function exits non-zero and emits a single stderr message. The message begins with the literal function-name prefix `extract_section_fence_aware:` (so callers can grep for it) and includes the anchor heading value passed by the caller. The two error paths are distinguishable by message body: the missing-anchor path's message body identifies that the anchor heading was not found; the empty-region path's message body identifies that the anchor was located but no content sat between it and the next heading.
  - A region containing only whitespace (blank lines, spaces, tabs) between anchor heading and next heading triggers the 'no content found' error path (treated as empty).
  - The anchor line itself is included in the function output (consistent with the prior `extract_review_round` contract)
  - Both migrated call sites in `test-skill-md-content-patterns.bats` produce output identical to the prior inline `extract_review_round` output for the same input files
  - Removing the inline `extract_review_round` definition from `test-skill-md-content-patterns.bats` causes no test failures in that suite
  - All pre-existing `extract_section` tests in `tests/unit/test-helpers-skill-markdown.bats` continue to pass with no changes
