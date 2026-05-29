---
finding: F01
reviewer: sf-claude
round: 2
task: task-09
severity: medium
change_type: correctness
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 19-27
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F01 — CRLF line endings cause `_frontmatter` to silently skip frontmatter detection

The `_frontmatter` awk helper uses `/^---$/` to detect YAML frontmatter delimiters. On any file with CRLF line endings, `awk` sees each line as `---\r`, not `---`. The pattern never fires, `n` stays 0, and the helper produces **empty output**. The downstream `grep -nE '^model:'` finds nothing, `offending_line` stays empty, and `violations` stays 0. The file **silently passes** even if its frontmatter carries `model: sonnet`.

The same blind spot applies to the scope-fence test (line 134) and the per-file message-shape test (line 88).

## Why it matters

A Windows contributor, a GitHub web edit, or certain CI automation tools can introduce CRLF without a `.gitattributes` guard. The lint reports green while the invariant is violated, with no error or warning.

## Fix

Add `{ sub(/\r$/, "") }` as the first awk rule inside `_frontmatter`, or pipe through `tr -d '\r'` before `grep`.
