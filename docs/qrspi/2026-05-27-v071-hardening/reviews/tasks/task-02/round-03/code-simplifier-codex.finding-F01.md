---
reviewer: code-simplifier-codex
task: 2
round: 3
finding: F01
severity: suggestion
change_type: style
status: advisory-not-applied
model: gpt-5.3-codex
timestamp: 2026-05-28T16:50:00Z
agent_id: t02-r3-code-simplifier-codex
orchestrator_decision: noted, not applied — Claude code-simplifier round-03 review explicitly judged the existing bash patterns intentional ("the non-quiet final grep aids failure diagnosis"). Reviewer-disagreement; orchestrator defers to the broader-context Claude judgment for this suggestion-severity finding.
---

# F01 — Suggestion: collapse pre-condition guard nested-if

## Location

`tests/unit/test-commit-hygiene-invariants.bats` (approximately lines 246-251)

## Suggested simplification

Collapse the nested `if -f` then `grep -qF` pattern into a single `&&`-chained guard:

```bash
if [ -f "$fresh_dir/.git/info/exclude" ] && \
   grep -qF ".qrspi-commit-msg.txt" "$fresh_dir/.git/info/exclude"; then
  printf 'FAIL: pre-condition violated - .git/info/exclude already contains scratch path\n' >&2
  return 1
fi
```

Same behavior, one less level of indentation/branching.

## Orchestrator decision

Not applied. Severity: suggestion (non-blocking). Claude code-simplifier round-03 review explicitly approved the existing pattern with no findings. Suggestion-severity reviewer disagreement defaults to preserving the existing pattern.
