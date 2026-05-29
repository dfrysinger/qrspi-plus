---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-agent-frontmatter-no-model.bats]
artifact: task-09/tests/unit/test-agent-frontmatter-no-model.bats
round: 4
reviewer: sf-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
---

**Title:** `in_scalar` never cleared when block scalar is the last frontmatter key (scalar-at-end silent path)

**Location:** `tests/unit/test-agent-frontmatter-no-model.bats:35–38`

The `in_scalar = 0` reset:
```awk
else if (in_scalar && /^[^[:space:]]/ && !/^---$/) { in_scalar = 0 }
```
requires a **non-whitespace, non-`---`** line to appear before the closing `---`. When a block scalar is the last key in the frontmatter block (nothing follows except the closing `---`), no such line ever appears.

Scenario:
```yaml
---
name: test
description: |
  Some description text
  spanning multiple lines
---
body content here
model: something at body start
```

When the closing `---` is reached, `/^---$/` fires but `!in_scalar` is false → skip `n++`. Then `n==1` rule: `!/^---$/` is false → no clear; prints `---`. The function **never exits** — it silently widens the scan window to include body content. The lint grep `'^model:'` then fires on body prose, producing a **false-positive violation**.

The block-scalar test fixture at lines 185–194 **does not cover this path**: it has `model: sonnet` after the inner `---`, which clears `in_scalar` before the final delimiter is reached. The scalar-at-end scenario is untested.

**Fix:** Add `else if (in_scalar && /^---$/ && /^---$/) { in_scalar = 0 }` reset on the closing delimiter when in_scalar is active — OR refactor the awk to track frontmatter-delimiter pairs more robustly (count balanced `---` only at column-0 with no scalar context).
