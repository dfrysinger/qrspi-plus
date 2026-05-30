---
finding: F02
reviewer: cq-claude
round: 2
task: task-03
severity: low
change_type: clarity
file: tests/helpers/skill-markdown.bash
lines: 49
persistence_note: orchestrator-persisted (chat-only fallback)
---

# Cryptic awk variable name `in_b` — rename to `in_section`

## Location

`tests/helpers/skill-markdown.bash` line 49 (awk `BEGIN` block) and throughout the awk program:

```awk
BEGIN { fence = 0; in_b = 0; found = 0; has_content = 0 }
```

Used at lines ~53, 57, 61, 64, 68.

## Issue

`in_b` is an unexplained abbreviation. "b" could stand for "block", "body", "boundary", "before", or "between". The surrounding variables (`fence`, `found`, `has_content`) are all self-documenting; `in_b` breaks the pattern.

The original `extract_review_round` used the same name, but that was a 9-line inline helper — here it lives in a shared library intended for long-term reuse, where readability matters more.

`in_section` (or `in_target`) would be unambiguous and consistent with the plain-English description in the block comment above the function ("Extracts from the anchor heading line … through the last line before the next … boundary").

## Suggested rename

```awk
BEGIN { fence = 0; in_section = 0; found = 0; has_content = 0 }
```

with all subsequent `in_b` references replaced by `in_section`.
