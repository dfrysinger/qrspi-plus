---
finding: F02
reviewer: sf-claude
round: 2
task: task-09
severity: low
change_type: correctness
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 19-27
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F02 — Embedded bare `---` inside a YAML block scalar exits `_frontmatter` prematurely

The awk script exits on the **second** line matching `/^---$/`. If any agent's YAML `description:` or other field uses a multi-line block scalar that contains the literal text `---` flush at column 0, awk treats it as the closing delimiter and exits early. Any `model:` key appearing after that embedded line in the frontmatter would be silently excluded from the scan window and the file would pass the check.

Concretely:
```yaml
description: |
  Some preamble
  ---
  More text
model: sonnet
```
would cause awk to stop printing after the embedded `---`, never collecting the `model:` line.

## Why it matters

Low probability for these specific agent files today, but adds up to structural brittleness. An agent file amended to use a richer block scalar could silently bypass the lint.

## Fix

Track nesting depth or use a flag variable to confirm the second `---` is not inside a quoted/block-scalar value, or add a defensive integration test asserting any file containing `---` in its description still has its `model:` key detected.
