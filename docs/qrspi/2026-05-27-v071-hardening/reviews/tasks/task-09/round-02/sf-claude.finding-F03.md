---
finding: F03
reviewer: sf-claude
round: 2
task: task-09
severity: low
change_type: correctness
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 55-68
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F03 — An agent file with no frontmatter at all silently passes the sweep

If an agent file has no `---` delimiters (e.g., its frontmatter was accidentally stripped), the awk helper returns empty. `grep` finds nothing, `violations` stays 0, and the file is treated as "clean." The test cannot distinguish "correctly has no `model:` key" from "has no parseable frontmatter at all."

The count test in the first `@test` block would catch a *deleted* file, but a file that loses only its frontmatter block while its body prose remains intact would still count as 1 toward the 41, and would silently pass the sweep.

## Why it matters

The task's correctness goal is "no `model:` in any frontmatter." A silently frontmatter-less file trivially satisfies that condition, but may indicate a content-loss bug.

## Fix

Add a companion assertion that verifies each file has at least one frontmatter delimiter:

```bash
if ! grep -q '^---$' "$f"; then
  violations=$((violations + 1))
  offenders="${offenders}${f}: missing YAML frontmatter delimiters"$'\n'
fi
```
